import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foldable_devices_ui/src/widgets/app_action.dart';

void main() {
  testWidgets('moves FAB and icon actions into the Duo registry', (
    tester,
  ) async {
    final AppActionRegistry registry = AppActionRegistry();
    var fabPresses = 0;
    var iconPresses = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AppActionScope(
          isIphoneDuo: true,
          registry: registry,
          iconRasterizer: _rasterizeForTest,
          child: Scaffold(
            body: ToolBar(
              child: <Widget>[
                FloatingActionButton(
                  tooltip: 'Add',
                  onPressed: () => fabPresses++,
                  child: const Icon(Icons.add),
                ),
                IconButton(
                  tooltip: 'Search',
                  onPressed: () => iconPresses++,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(registry.registeredSourceCount, 1);
    expect(registry.activeActions, hasLength(2));
    expect(registry.activeActions[0].role, AppActionRole.primary);
    expect(
      registry.activeActions[0].priority,
      greaterThan(registry.activeActions[1].priority),
    );
    expect(registry.activeActions[0].label, 'Add');
    expect(registry.activeActions[0].iconBytes, isNotEmpty);
    expect(
      registry.activeActions[0].iconBytes,
      _encodedGlyph(Icons.add.codePoint),
    );
    expect(registry.activeActions[1].role, AppActionRole.action);
    expect(registry.activeActions[1].label, 'Search');
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(IconButton), findsNothing);

    registry.activeActions[0].onPressed();
    registry.activeActions[1].onPressed();
    expect(fabPresses, 1);
    expect(iconPresses, 1);

    registry.dispose();
  });

  testWidgets('moves BottomNavigationBar destinations with selected state', (
    tester,
  ) async {
    final AppActionRegistry registry = AppActionRegistry();
    int? selectedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: AppActionScope(
          isIphoneDuo: true,
          registry: registry,
          iconRasterizer: _rasterizeForTest,
          child: Scaffold(
            body: ToolBar(
              child: <Widget>[
                BottomNavigationBar(
                  currentIndex: 1,
                  onTap: (index) => selectedIndex = index,
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.bookmark_border),
                      activeIcon: Icon(Icons.bookmark),
                      label: 'Saved',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(registry.activeActions, hasLength(2));
    expect(registry.activeActions[0].role, AppActionRole.destination);
    expect(registry.activeActions[0].isSelected, isFalse);
    expect(registry.activeActions[1].isSelected, isTrue);
    expect(registry.activeActions[1].selectedIconBytes, isNotEmpty);
    registry.activeActions[0].onPressed();
    expect(selectedIndex, 0);

    registry.dispose();
  });

  testWidgets('AppBarBackButtonWidget registers a native back action', (
    tester,
  ) async {
    final AppActionRegistry registry = AppActionRegistry();

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppActionScope(
          isIphoneDuo: true,
          registry: registry,
          iconRasterizer: _rasterizeForTest,
          child: child!,
        ),
        home: const Scaffold(body: _BackRouteLauncher()),
        routes: <String, WidgetBuilder>{
          '/detail': (_) => AppActionScope(
            isIphoneDuo: true,
            registry: registry,
            iconRasterizer: _rasterizeForTest,
            child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: const AppBarBackButtonWidget(),
              ),
            ),
          ),
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open detail'));
    await tester.pumpAndSettle();

    expect(registry.activeActions, hasLength(1));
    expect(registry.activeActions.single.role, AppActionRole.back);
    expect(find.byType(IconButton), findsNothing);

    registry.dispose();
  });

  testWidgets('keeps the original child outside iPhone Duo', (tester) async {
    final AppActionRegistry registry = AppActionRegistry();

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppActionScope(
          isIphoneDuo: false,
          registry: registry,
          child: child!,
        ),
        home: Scaffold(
          body: ToolBar(
            child: <Widget>[
              FloatingActionButton(onPressed: null, child: Icon(Icons.add)),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(registry.activeActions, isEmpty);
    registry.dispose();
  });

  testWidgets('Navigator observer updates native back availability', (
    tester,
  ) async {
    final AppActionRegistry registry = AppActionRegistry();
    final AppActionNavigatorObserver observer = AppActionNavigatorObserver(
      registry,
    );
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: <NavigatorObserver>[observer],
        home: const Scaffold(body: Text('root')),
        routes: <String, WidgetBuilder>{
          '/detail': (_) => const Scaffold(body: Text('detail')),
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(registry.canPop, isFalse);

    navigatorKey.currentState!.pushNamed('/detail');
    await tester.pumpAndSettle();
    expect(registry.canPop, isTrue);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(registry.canPop, isFalse);

    registry.dispose();
  });
}

class _BackRouteLauncher extends StatelessWidget {
  const _BackRouteLauncher();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).pushNamed('/detail'),
        child: const Text('Open detail'),
      ),
    );
  }
}

Future<Uint8List?> _rasterizeForTest(BuildContext context, Widget icon) async {
  if (icon is! Icon || icon.icon == null) return null;
  return _encodedGlyph(icon.icon!.codePoint);
}

Uint8List _encodedGlyph(int codePoint) => Uint8List.fromList(<int>[
  codePoint & 0xff,
  (codePoint >> 8) & 0xff,
  (codePoint >> 16) & 0xff,
  (codePoint >> 24) & 0xff,
]);
