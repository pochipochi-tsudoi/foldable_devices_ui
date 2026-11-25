import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foldable_devices_ui/foldable_devices_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel deviceChannel = MethodChannel(
    'foldable_devices_ui/device',
  );

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(deviceChannel, null);
  });

  void setDuoResult(bool isDuo) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(deviceChannel, (call) async => isDuo);
  }

  testWidgets('does not add SafeArea on non-Duo devices', (tester) async {
    setDuoResult(false);
    await tester.pumpWidget(
      const DuoSafeArea(child: MaterialApp(home: _RegularPage())),
    );
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.byKey(const ValueKey<String>('regular-page')),
        matching: find.byType(SafeArea),
      ),
      findsNothing,
    );
  });

  testWidgets('applies side SafeArea except to configured page types', (
    tester,
  ) async {
    setDuoResult(true);
    await tester.pumpWidget(
      const DuoSafeArea(
        exception: <Type>[_FullBleedPage],
        child: MaterialApp(home: _RegularPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.byKey(const ValueKey<String>('regular-page')),
        matching: find.byType(SafeArea),
      ),
      findsOneWidget,
    );
    final SafeArea safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
    expect(safeArea.left, isTrue);
    expect(safeArea.right, isTrue);
    expect(safeArea.top, isFalse);
    expect(safeArea.bottom, isFalse);

    await tester.pumpWidget(
      const DuoSafeArea(
        exception: <Type>[_FullBleedPage],
        child: MaterialApp(home: _FullBleedPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.byKey(const ValueKey<String>('full-bleed-page')),
        matching: find.byType(SafeArea),
      ),
      findsNothing,
    );
  });

  testWidgets('paints only the left and right safe-area strips', (
    tester,
  ) async {
    setDuoResult(true);
    const Color backgroundColor = Colors.deepPurple;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.fromLTRB(36, 24, 18, 32),
        ),
        child: const DuoSafeArea(
          backgroundColor: backgroundColor,
          child: MaterialApp(home: _RegularPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder leftBackground = find.byKey(
      const ValueKey<String>('duoSafeArea.leftBackground'),
    );
    final Finder rightBackground = find.byKey(
      const ValueKey<String>('duoSafeArea.rightBackground'),
    );
    expect(leftBackground, findsOneWidget);
    expect(rightBackground, findsOneWidget);
    expect(tester.getRect(leftBackground).width, 36);
    expect(tester.getRect(rightBackground).width, 18);
    expect(tester.getRect(leftBackground).top, 0);
    expect(
      tester.getSize(leftBackground).height,
      tester.view.physicalSize.height / tester.view.devicePixelRatio,
    );
    expect(
      tester
          .widget<ColoredBox>(
            find.descendant(
              of: leftBackground,
              matching: find.byType(ColoredBox),
            ),
          )
          .color,
      backgroundColor,
    );
    expect(
      tester.getRect(find.byKey(const ValueKey<String>('regular-page'))).top,
      0,
    );
  });

  testWidgets('does not paint safe-area background on exception or non-Duo', (
    tester,
  ) async {
    setDuoResult(true);
    await tester.pumpWidget(
      const DuoSafeArea(
        exception: <Type>[_FullBleedPage],
        backgroundColor: Colors.deepPurple,
        child: MaterialApp(home: _FullBleedPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('duoSafeArea.leftBackground')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('duoSafeArea.rightBackground')),
      findsNothing,
    );

    setDuoResult(false);
    await tester.pumpWidget(
      const DuoSafeArea(
        backgroundColor: Colors.deepPurple,
        child: MaterialApp(home: _RegularPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('duoSafeArea.leftBackground')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('duoSafeArea.rightBackground')),
      findsNothing,
    );
  });

  testWidgets('applies the exception list to named routes', (tester) async {
    setDuoResult(true);
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      DuoSafeArea(
        exception: const <Type>[_FullBleedPage],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const _RegularPage(),
          routes: <String, WidgetBuilder>{
            '/full-bleed': (_) => const _FullBleedPage(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pushNamed('/full-bleed');
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.byKey(const ValueKey<String>('full-bleed-page')),
        matching: find.byType(SafeArea),
      ),
      findsNothing,
    );
  });

  testWidgets('DuoSafeArea.route handles imperative routes', (tester) async {
    setDuoResult(true);
    await tester.pumpWidget(
      const DuoSafeArea(child: MaterialApp(home: _PushPage())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('push-route')));
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.byKey(const ValueKey<String>('regular-page')),
        matching: find.byType(SafeArea),
      ),
      findsOneWidget,
    );
    final SafeArea safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
    expect(safeArea.top, isFalse);
    expect(safeArea.bottom, isFalse);
  });

  testWidgets(
    'keeps DuoVerticalBottomNav fixed at bottom on Inner Display half-screen (left/right only)',
    (tester) async {
      tester.view.physicalSize = const Size(475, 669);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(deviceChannel, (call) async {
            if (call.method == 'isIphoneDuo') return true;
            if (call.method == 'getBarLayoutInsets') {
              return <String, Object?>{
                'top': 0.0,
                'bottom': 112.0,
                'hasPunchHoleAtBottom': true,
                'isOuterDisplay': false,
              };
            }
            return null;
          });

      await tester.pumpWidget(
        const DuoSafeArea(child: MaterialApp(home: _TabPage())),
      );
      await tester.pumpAndSettle();

      final Finder verticalNav = find.byKey(
        const ValueKey<String>('duoSafeArea.verticalBottomNav'),
      );
      expect(verticalNav, findsOneWidget);
      final Positioned positioned = tester.widget<Positioned>(verticalNav);
      expect(positioned.bottom, 16.0);
    },
  );

  testWidgets(
    'shifts DuoVerticalBottomNav vertically on Outer Display rotation',
    (tester) async {
      tester.view.physicalSize = const Size(678, 466);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool punchHoleAtBottom = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(deviceChannel, (call) async {
            if (call.method == 'isIphoneDuo') return true;
            if (call.method == 'getBarLayoutInsets') {
              return <String, Object?>{
                'top': punchHoleAtBottom ? 0.0 : 82.0,
                'bottom': punchHoleAtBottom ? 112.0 : 16.0,
                'hasPunchHoleAtBottom': punchHoleAtBottom,
                'isOuterDisplay': true,
              };
            }
            return null;
          });

      await tester.pumpWidget(
        const DuoSafeArea(child: MaterialApp(home: _TabPage())),
      );
      await tester.pumpAndSettle();

      final Finder verticalNav = find.byKey(
        const ValueKey<String>('duoSafeArea.verticalBottomNav'),
      );
      expect(verticalNav, findsOneWidget);
      expect(tester.widget<Positioned>(verticalNav).bottom, 112.0);

      // Rotate outer display so Dynamic Island moves away from bottom.
      punchHoleAtBottom = false;
      tester.binding.handleMetricsChanged();
      await tester.pumpAndSettle();

      expect(tester.widget<Positioned>(verticalNav).bottom, 16.0);
    },
  );
}

class _TabPage extends StatelessWidget {
  const _TabPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const SizedBox.expand(),
      bottomNavigationBar: DuoTabBar(
        child: BottomNavigationBar(
          currentIndex: 0,
          onTap: (_) {},
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          ],
        ),
      ),
    );
  }
}

class _RegularPage extends StatelessWidget {
  const _RegularPage();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      key: ValueKey<String>('regular-page'),
      color: Colors.white,
    );
  }
}

class _FullBleedPage extends StatelessWidget {
  const _FullBleedPage();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      key: ValueKey<String>('full-bleed-page'),
      color: Colors.black,
    );
  }
}

class _PushPage extends StatelessWidget {
  const _PushPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          key: const ValueKey<String>('push-route'),
          onPressed: () {
            Navigator.of(context).push(
              DuoSafeArea.route<void>(builder: (_) => const _RegularPage()),
            );
          },
          child: const Text('Push'),
        ),
      ),
    );
  }
}
