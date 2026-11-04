import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foldable_devices_ui/foldable_devices_ui.dart';
import 'package:foldable_devices_ui/src/state/width_state.dart';
import 'package:foldable_devices_ui/src/widgets/app_action.dart';

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

  group('DuoTabBar Native Bridge', () {
    testWidgets('renders child directly when not on iPhone Duo', (
      tester,
    ) async {
      final AppActionRegistry registry = AppActionRegistry();

      await tester.pumpWidget(
        MaterialApp(
          home: AppActionScope(
            isIphoneDuo: false,
            registry: registry,
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

      // Child is rendered directly in Flutter tree
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(registry.registeredSourceCount, 0);

      registry.dispose();
    });

    testWidgets('renders child directly when DeviceWidthState is false (folded screen)', (
      tester,
    ) async {
      final DeviceWidthState widthState = DeviceWidthState(false);
      final AppActionRegistry registry = AppActionRegistry();

      await tester.pumpWidget(
        MaterialApp(
          home: AppActionScope(
            isIphoneDuo: true,
            registry: registry,
            deviceWidthState: widthState,
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

      // Child is rendered directly because screen is folded/narrow
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(registry.registeredSourceCount, 0);

      registry.dispose();
    });

    testWidgets(
      'registers destination actions into AppActionRegistry on unfolded iPhone Duo (useIndependence: false)',
      (tester) async {
        final DeviceWidthState widthState = DeviceWidthState(true);
        final AppActionRegistry registry = AppActionRegistry();
        int? tappedIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: AppActionScope(
              isIphoneDuo: true,
              registry: registry,
              deviceWidthState: widthState,
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

        // Child is replaced by native placeholder; Flutter BottomNavigationBar is not rendered
        expect(find.byType(BottomNavigationBar), findsNothing);

        // Registered in registry as destination actions
        expect(registry.registeredSourceCount, 1);
        expect(registry.activeActions, hasLength(2));
        expect(registry.activeActions[0].role, AppActionRole.destination);
        expect(registry.activeActions[0].isIndependent, false);
        expect(registry.activeActions[0].isSelected, true);
        expect(registry.activeActions[1].isSelected, false);

        // Tap triggers callback
        registry.activeActions[1].onPressed();
        expect(tappedIndex, 1);

        registry.dispose();
      },
    );

    testWidgets('registers independent actions with useIndependence: true', (
      tester,
    ) async {
      final DeviceWidthState widthState = DeviceWidthState(true);
      final AppActionRegistry registry = AppActionRegistry();

      await tester.pumpWidget(
        MaterialApp(
          home: AppActionScope(
            isIphoneDuo: true,
            registry: registry,
            deviceWidthState: widthState,
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

      expect(registry.registeredSourceCount, 1);
      expect(registry.activeActions, hasLength(2));
      expect(registry.activeActions[0].isIndependent, true);
      expect(registry.activeActions[1].isIndependent, true);

      registry.dispose();
    });

    testWidgets('supports FloatingActionButton and coexists with BottomNavigationBar', (
      tester,
    ) async {
      final DeviceWidthState widthState = DeviceWidthState(true);
      final AppActionRegistry registry = AppActionRegistry();
      int fabClickCount = 0;
      int tabIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: AppActionScope(
            isIphoneDuo: true,
            registry: registry,
            deviceWidthState: widthState,
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

      // BOTH sources coexist simultaneously without overwriting or disappearing!
      expect(registry.registeredSourceCount, 2);

      // FAB is primary & independent
      final fabAction = registry.activeActions.firstWhere(
        (a) => a.role == AppActionRole.primary,
      );
      expect(fabAction.isIndependent, true);
      expect(fabAction.label, 'Increment');

      fabAction.onPressed();
      expect(fabClickCount, 1);

      // Tab destinations are attached (not independent)
      final tabDestinations = registry.activeActions.where(
        (a) => a.role == AppActionRole.destination,
      ).toList();
      expect(tabDestinations, hasLength(2));
      expect(tabDestinations[0].isIndependent, false);
      expect(tabDestinations[1].isIndependent, false);

      registry.dispose();
    });

    testWidgets('handles NavigationBar and selection callback correctly', (
      tester,
    ) async {
      final DeviceWidthState widthState = DeviceWidthState(true);
      final AppActionRegistry registry = AppActionRegistry();
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: AppActionScope(
            isIphoneDuo: true,
            registry: registry,
            deviceWidthState: widthState,
            iconRasterizer: mockRasterizer,
            child: Scaffold(
              bottomNavigationBar: DuoTabBar(
                useIndependence: false,
                child: NavigationBar(
                  selectedIndex: 0,
                  onDestinationSelected: (index) => selectedIndex = index,
                  destinations: const <NavigationDestination>[
                    NavigationDestination(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
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

      expect(registry.registeredSourceCount, 1);
      expect(registry.activeActions, hasLength(2));
      expect(registry.activeActions[0].isSelected, true);
      expect(registry.activeActions[1].isSelected, false);

      registry.activeActions[1].onPressed();
      expect(selectedIndex, 1);

      registry.dispose();
    });
  });
}
