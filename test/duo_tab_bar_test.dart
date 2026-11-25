import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foldable_devices_ui/foldable_devices_ui.dart';
import 'package:foldable_devices_ui/src/state/width_state.dart';
import 'package:foldable_devices_ui/src/widgets/app_action.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> channelCalls = <MethodCall>[];

  setUp(() {
    channelCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('foldable_devices_ui/device'),
          (MethodCall methodCall) async {
            channelCalls.add(methodCall);
            return null;
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('foldable_devices_ui/device'),
          null,
        );
  });

  Future<Uint8List?> mockRasterizer(BuildContext context, Widget icon) async {
    return Uint8List.fromList(<int>[1, 2, 3]);
  }

  group('DuoTabBar', () {
    testWidgets(
      'renders BottomNavigationBar directly on small non-Duo screens',
      (tester) async {
        final DeviceWidthState widthState = DeviceWidthState(false);
        final AppActionRegistry registry = AppActionRegistry();
        final DuoBottomNavRegistry bottomNavRegistry = DuoBottomNavRegistry();

        await tester.pumpWidget(
          MaterialApp(
            home: AppActionScope(
              isIphoneDuo: false,
              registry: registry,
              bottomNavRegistry: bottomNavRegistry,
              deviceWidthState: widthState,
              useModernMaterial: true,
              iconRasterizer: mockRasterizer,
              child: Scaffold(
                bottomNavigationBar: DuoTabBar(
                  useIndependence: false,
                  child: BottomNavigationBar(
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.search),
                        label: 'Search',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(registry.registeredSourceCount, 0);
        expect(bottomNavRegistry.registeredSourceCount, 0);

        widthState.dispose();
        bottomNavRegistry.dispose();
        registry.dispose();
      },
    );

    testWidgets(
      'relocates BottomNavigationBar into DuoBottomNavRegistry on folded iPhone Duo',
      (tester) async {
        final DeviceWidthState widthState = DeviceWidthState(false);
        final AppActionRegistry registry = AppActionRegistry();
        final DuoBottomNavRegistry bottomNavRegistry = DuoBottomNavRegistry();
        int? tappedIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: AppActionScope(
              isIphoneDuo: true,
              registry: registry,
              bottomNavRegistry: bottomNavRegistry,
              deviceWidthState: widthState,
              useModernMaterial: true,
              iconRasterizer: mockRasterizer,
              child: Scaffold(
                bottomNavigationBar: DuoTabBar(
                  useIndependence: false,
                  child: BottomNavigationBar(
                    currentIndex: 0,
                    onTap: (index) => tappedIndex = index,
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.search),
                        label: 'Search',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // BottomNavigationBar is hidden in the Scaffold slot and hosted via DuoBottomNavRegistry.
        expect(find.byType(BottomNavigationBar), findsNothing);
        expect(registry.registeredSourceCount, 0);
        expect(bottomNavRegistry.registeredSourceCount, 1);

        final DuoBottomNavEntry? entry = bottomNavRegistry.activeEntry;
        expect(entry, isNotNull);
        expect(entry!.items, hasLength(2));
        expect(entry.selectedIndex, 0);
        expect(entry.useIndependence, isFalse);

        entry.onSelected?.call(1);
        expect(tappedIndex, 1);

        widthState.dispose();
        bottomNavRegistry.dispose();
        registry.dispose();
      },
    );

    testWidgets(
      'relocates BottomNavigationBar with useIndependence: true on unfolded iPhone Duo',
      (tester) async {
        final DeviceWidthState widthState = DeviceWidthState(true);
        final AppActionRegistry registry = AppActionRegistry();
        final DuoBottomNavRegistry bottomNavRegistry = DuoBottomNavRegistry();

        await tester.pumpWidget(
          MaterialApp(
            home: AppActionScope(
              isIphoneDuo: true,
              registry: registry,
              bottomNavRegistry: bottomNavRegistry,
              deviceWidthState: widthState,
              useModernMaterial: true,
              iconRasterizer: mockRasterizer,
              child: Scaffold(
                bottomNavigationBar: DuoTabBar(
                  useIndependence: true,
                  child: BottomNavigationBar(
                    currentIndex: 1,
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.search),
                        label: 'Search',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BottomNavigationBar), findsNothing);
        expect(registry.registeredSourceCount, 0);
        expect(bottomNavRegistry.registeredSourceCount, 1);
        expect(bottomNavRegistry.activeEntry?.selectedIndex, 1);
        expect(bottomNavRegistry.activeEntry?.useIndependence, isTrue);

        widthState.dispose();
        bottomNavRegistry.dispose();
        registry.dispose();
      },
    );

    testWidgets(
      'renders DuoVerticalBottomNav directly on iPhone Duo without DuoBottomNavRegistry',
      (tester) async {
        final AppActionRegistry registry = AppActionRegistry();

        await tester.pumpWidget(
          MaterialApp(
            home: AppActionScope(
              isIphoneDuo: true,
              registry: registry,
              useModernMaterial: true,
              iconRasterizer: mockRasterizer,
              child: Scaffold(
                bottomNavigationBar: DuoTabBar(
                  child: BottomNavigationBar(
                    currentIndex: 0,
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.search),
                        label: 'Search',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BottomNavigationBar), findsNothing);
        expect(find.byType(DuoVerticalBottomNav), findsOneWidget);

        registry.dispose();
      },
    );

    testWidgets(
      'converts BottomNavigationBar to NavigationRail on non-Duo large screens',
      (tester) async {
        final DeviceWidthState widthState = DeviceWidthState(true);
        final AppActionRegistry registry = AppActionRegistry();
        int? selectedIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: AppActionScope(
              isIphoneDuo: false,
              registry: registry,
              deviceWidthState: widthState,
              useModernMaterial: true,
              iconRasterizer: mockRasterizer,
              child: Scaffold(
                body: DuoTabBar(
                  child: BottomNavigationBar(
                    currentIndex: 0,
                    onTap: (index) => selectedIndex = index,
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.settings),
                        label: 'Settings',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BottomNavigationBar), findsNothing);
        expect(find.byType(NavigationRail), findsOneWidget);

        final NavigationRail rail = tester.widget<NavigationRail>(
          find.byType(NavigationRail),
        );
        expect(rail.selectedIndex, 0);
        rail.onDestinationSelected?.call(1);
        expect(selectedIndex, 1);

        widthState.dispose();
        registry.dispose();
      },
    );

    testWidgets(
      'supports FloatingActionButton in AppActionRegistry and coexists with BottomNavigationBar',
      (tester) async {
        final DeviceWidthState widthState = DeviceWidthState(true);
        final AppActionRegistry registry = AppActionRegistry();
        final DuoBottomNavRegistry bottomNavRegistry = DuoBottomNavRegistry();
        int fabClickCount = 0;
        int tabIndex = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: AppActionScope(
              isIphoneDuo: true,
              registry: registry,
              bottomNavRegistry: bottomNavRegistry,
              deviceWidthState: widthState,
              useModernMaterial: true,
              iconRasterizer: mockRasterizer,
              child: Scaffold(
                floatingActionButton: DuoTabBar(
                  useIndependence: true,
                  child: FloatingActionButton(
                    onPressed: () => fabClickCount++,
                    tooltip: 'Increment',
                    child: const Icon(Icons.add),
                  ),
                ),
                bottomNavigationBar: DuoTabBar(
                  useIndependence: false,
                  child: BottomNavigationBar(
                    currentIndex: tabIndex,
                    onTap: (index) => tabIndex = index,
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.search),
                        label: 'Search',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // FAB is hosted in AppActionRegistry as a primary action.
        expect(find.byType(FloatingActionButton), findsNothing);
        expect(registry.registeredSourceCount, 1);
        final AppAction fabAction = registry.activeActions.single;
        expect(fabAction.role, AppActionRole.primary);
        expect(fabAction.isIndependent, isTrue);
        expect(fabAction.label, 'Increment');

        fabAction.onPressed();
        expect(fabClickCount, 1);

        // BottomNavigationBar is simultaneously hosted in DuoBottomNavRegistry.
        expect(find.byType(BottomNavigationBar), findsNothing);
        expect(bottomNavRegistry.registeredSourceCount, 1);
        final DuoBottomNavEntry? navEntry = bottomNavRegistry.activeEntry;
        expect(navEntry, isNotNull);
        expect(navEntry!.items, hasLength(2));
        expect(navEntry.useIndependence, isFalse);

        navEntry.onSelected?.call(1);
        expect(tabIndex, 1);

        widthState.dispose();
        bottomNavRegistry.dispose();
        registry.dispose();
      },
    );

    testWidgets(
      'keeps FloatingActionButton rendered in Flutter on non-Duo large screens',
      (tester) async {
        final DeviceWidthState widthState = DeviceWidthState(true);
        final AppActionRegistry registry = AppActionRegistry();

        await tester.pumpWidget(
          MaterialApp(
            home: AppActionScope(
              isIphoneDuo: false,
              registry: registry,
              deviceWidthState: widthState,
              useModernMaterial: true,
              iconRasterizer: mockRasterizer,
              child: Scaffold(
                floatingActionButton: DuoTabBar(
                  useIndependence: true,
                  child: FloatingActionButton(
                    onPressed: () {},
                    tooltip: 'Increment',
                    child: const Icon(Icons.add),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(registry.registeredSourceCount, 0);

        widthState.dispose();
        registry.dispose();
      },
    );
  });
}
