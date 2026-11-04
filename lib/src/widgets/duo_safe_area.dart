import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../platform/duo_device_info.dart';
import '../state/width_state.dart';
import 'app_action.dart';
import 'duo_tab_bar.dart';

/// Applies the side safe-area insets to each Material route on iPhone Duo,
/// except [exception] widget types.
///
/// Wrap a Navigator-based [MaterialApp] once:
///
/// ```dart
/// DuoSafeArea(
///   exception: const [FullScreenPage],
///   backgroundColor: Colors.black,
///   child: MaterialApp(home: const HomePage()),
/// )
/// ```
///
/// For imperative navigation with [Navigator.push], use [DuoSafeArea.route]
/// to create the route so its page can be checked against [exception].
class DuoSafeArea extends StatefulWidget {
  const DuoSafeArea({
    super.key,
    this.exception = const <Type>[],
    this.backgroundColor,
    required this.child,
  }) : assert(child is MaterialApp, 'DuoSafeArea.child must be a MaterialApp.');

  /// Widget runtime types that should not receive the automatic [SafeArea].
  final List<Type> exception;

  /// Background color for the side safe-area regions on iPhone Duo.
  ///
  /// The color is painted only behind the left and right inset regions.
  /// Defaults to transparent.
  final Color? backgroundColor;

  /// The Navigator-based MaterialApp whose routes will receive SafeArea.
  final Widget child;

  /// Creates a MaterialPageRoute that participates in DuoSafeArea handling.
  ///
  /// Use this for imperative pushes. Routes pushed directly with
  /// `MaterialPageRoute` bypass the route builders configured by MaterialApp.
  static MaterialPageRoute<T> route<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
    bool? requestFocus,
    bool allowSnapshotting = true,
    bool barrierDismissible = false,
    TraversalEdgeBehavior? traversalEdgeBehavior,
    TraversalEdgeBehavior? directionalTraversalEdgeBehavior,
  }) {
    return MaterialPageRoute<T>(
      builder: (context) {
        final Widget page = builder(context);
        final _DuoSafeAreaScope? scope = context
            .dependOnInheritedWidgetOfExactType<_DuoSafeAreaScope>();
        return scope?.wrap(page) ?? page;
      },
      settings: settings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
      requestFocus: requestFocus,
      allowSnapshotting: allowSnapshotting,
      barrierDismissible: barrierDismissible,
      traversalEdgeBehavior: traversalEdgeBehavior,
      directionalTraversalEdgeBehavior: directionalTraversalEdgeBehavior,
    );
  }

  @override
  State<DuoSafeArea> createState() => _DuoSafeAreaState();
}

class _DuoSafeAreaState extends State<DuoSafeArea> {
  static const MethodChannel _toolbarChannel = MethodChannel(
    'foldable_devices_ui/device',
  );
  static const String _groupedActionsId = 'duo.groupedActions';

  late final AppActionRegistry _actionRegistry;
  late final AppActionNavigatorObserver _actionNavigatorObserver;
  late final DeviceWidthState _deviceWidthState;
  Uint8List? _groupedMoreIconBytes;
  bool _isIphoneDuo = false;

  @override
  void initState() {
    super.initState();
    _actionRegistry = AppActionRegistry();
    _actionNavigatorObserver = AppActionNavigatorObserver(_actionRegistry);
    _deviceWidthState = DeviceWidthState();
    _actionRegistry.addListener(_syncNativeToolbar);
    _deviceWidthState.addListener(_syncNativeToolbar);
    _toolbarChannel.setMethodCallHandler(_handleNativeToolbarCall);
    _ensureGroupedMoreIcon();
    _loadDeviceType();
  }

  @override
  void reassemble() {
    _actionRegistry.clear();
    super.reassemble();
    _ensureGroupedMoreIcon();
    _syncNativeToolbar();
  }

  Future<void> _ensureGroupedMoreIcon() async {
    if (_groupedMoreIconBytes != null) return;
    final Uint8List? bytes = await rasterizeDefaultToolbarIcon(
      const Icon(Icons.more_horiz),
    );
    if (!mounted || bytes == null) return;
    _groupedMoreIconBytes = bytes;
    if (_isIphoneDuo) _syncNativeToolbar();
  }

  @override
  void dispose() {
    _actionRegistry.removeListener(_syncNativeToolbar);
    _deviceWidthState.removeListener(_syncNativeToolbar);
    _deviceWidthState.dispose();
    _actionRegistry.dispose();
    _toolbarChannel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DuoSafeArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      _loadDeviceType();
    }
  }

  Future<void> _loadDeviceType() async {
    final bool isIphoneDuo = await DuoDeviceInfo.isIphoneDuo;
    if (!mounted || isIphoneDuo == _isIphoneDuo) return;
    setState(() => _isIphoneDuo = isIphoneDuo);
    if (isIphoneDuo) _syncNativeToolbar();
  }

  Future<void> _handleNativeToolbarCall(MethodCall call) async {
    if (call.method == 'toolbarActionPressed') {
      final arguments = call.arguments;
      if (arguments is Map && arguments['id'] is String) {
        final String actionId = arguments['id'] as String;
        if (actionId == _groupedActionsId) {
          _showGroupedActionsSheet();
        } else {
          _actionRegistry.invoke(actionId);
        }
      }
    } else if (call.method == 'tabBarItemSelected') {
      final arguments = call.arguments;
      if (arguments is Map) {
        final int? index = arguments['index'] as int?;
        if (index != null) {
          DuoTabBar.notifyTabSelected(index);
        }
      }
    }
  }

  void _showGroupedActionsSheet() {
    final List<AppAction> secondaryActions = _actionRegistry.activeActions
        .where((a) => a.role == AppActionRole.action && a.isEnabled)
        .toList(growable: false);
    if (secondaryActions.isEmpty) return;
    if (secondaryActions.length == 1) {
      secondaryActions.single.onPressed();
      return;
    }

    final NavigatorState? navigator = _actionNavigatorObserver.navigator;
    final BuildContext? navContext =
        navigator?.overlay?.context ?? navigator?.context;
    if (navContext == null || !navContext.mounted) {
      secondaryActions.first.onPressed();
      return;
    }

    showCupertinoModalPopup<void>(
      context: navContext,
      builder: (sheetContext) => CupertinoActionSheet(
        actions: <Widget>[
          for (var i = 0; i < secondaryActions.length; i++)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                secondaryActions[i].onPressed();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (secondaryActions[i].iconBytes != null) ...<Widget>[
                    Image.memory(
                      secondaryActions[i].iconBytes!,
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      secondaryActions[i].label ?? 'Action ${i + 1}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _syncNativeToolbar() {
    if (!_isIphoneDuo) {
      return;
    }
    final List<AppAction> actions = _actionRegistry.activeActions;
    final bool hasExplicitBack = actions.any(
      (action) => action.role == AppActionRole.back,
    );

    final List<AppAction> backActions = actions
        .where((action) => action.role == AppActionRole.back)
        .toList(growable: false);
    final List<AppAction> secondaryActions = actions
        .where((action) => action.role == AppActionRole.action)
        .toList(growable: false);
    final List<AppAction> primaryActions = actions
        .where((action) => action.role == AppActionRole.primary)
        .toList(growable: false);

    final List<Map<String, Object?>> serializedActions =
        <Map<String, Object?>>[];

    for (final AppAction back in backActions) {
      final Map<String, Object?> map = Map<String, Object?>.of(
        back.toPlatformMap(),
      );
      map['independent'] = false;
      serializedActions.add(map);
    }

    // HIG: Group multiple secondary actions into a single menu item to fit the vertical bar.
    if (secondaryActions.length == 1) {
      final Map<String, Object?> map = Map<String, Object?>.of(
        secondaryActions.single.toPlatformMap(),
      );
      map['role'] = 'action';
      map['independent'] = false;
      serializedActions.add(map);
    } else if (secondaryActions.length > 1) {
      if (_groupedMoreIconBytes == null) {
        _ensureGroupedMoreIcon();
      }
      serializedActions.add(<String, Object?>{
        'id': _groupedActionsId,
        'role': 'action',
        'label': 'More',
        'icon': _groupedMoreIconBytes ?? secondaryActions.first.iconBytes,
        'selectedIcon': null,
        'priority': 50,
        'enabled': secondaryActions.any((action) => action.isEnabled),
        'selected': false,
        'independent': false,
        'children': <Map<String, Object?>>[
          for (final AppAction sub in secondaryActions) sub.toPlatformMap(),
        ],
      });
    }

    // Single primary action (FAB) consolidated into the same single toolbar group.
    if (primaryActions.isNotEmpty) {
      final AppAction primary = primaryActions.last;
      final Map<String, Object?> map = Map<String, Object?>.of(
        primary.toPlatformMap(),
      );
      map['role'] = 'action';
      map['independent'] = false;
      map['isPrimary'] = true;
      serializedActions.add(map);
    }

    _toolbarChannel
        .invokeMethod<void>('updateToolbarActions', <String, Object?>{
          'canPop': _actionRegistry.canPop && !hasExplicitBack,
          'actions': serializedActions,
        })
        .catchError((Object _) {});
  }

  Widget _wrapPage(Widget page) {
    return _DuoPageWrapper(
      isIphoneDuo: _isIphoneDuo,
      isException: widget.exception.contains(page.runtimeType),
      backgroundColor: widget.backgroundColor,
      actionRegistry: _actionRegistry,
      deviceWidthState: _deviceWidthState,
      page: page,
    );
  }

  Route<dynamic>? _wrapRoute(Route<dynamic>? route) {
    if (route is! MaterialPageRoute<dynamic>) {
      return route;
    }

    return MaterialPageRoute<dynamic>(
      builder: (context) => _wrapPage(route.builder(context)),
      settings: route.settings,
      maintainState: route.maintainState,
      fullscreenDialog: route.fullscreenDialog,
      requestFocus: route.requestFocus,
      allowSnapshotting: route.allowSnapshotting,
      barrierDismissible: route.barrierDismissible,
      traversalEdgeBehavior: route.traversalEdgeBehavior,
      directionalTraversalEdgeBehavior: route.directionalTraversalEdgeBehavior,
    );
  }

  MaterialApp _buildMaterialApp(MaterialApp app) {
    if (app.routerConfig != null || app.routerDelegate != null) {
      throw FlutterError(
        'DuoSafeArea currently supports Navigator-based MaterialApp, '
        'not MaterialApp.router.',
      );
    }

    final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
      for (final MapEntry<String, WidgetBuilder> entry in app.routes!.entries)
        entry.key: (BuildContext context) => _wrapPage(entry.value(context)),
    };

    return MaterialApp(
      key: app.key,
      navigatorKey: app.navigatorKey,
      scaffoldMessengerKey: app.scaffoldMessengerKey,
      home: app.home == null ? null : _wrapPage(app.home!),
      routes: routes,
      initialRoute: app.initialRoute,
      onGenerateRoute: app.onGenerateRoute == null
          ? null
          : (settings) => _wrapRoute(app.onGenerateRoute!(settings)),
      onGenerateInitialRoutes: app.onGenerateInitialRoutes == null
          ? null
          : (initialRoute) => app.onGenerateInitialRoutes!(initialRoute)
                .map((route) => _wrapRoute(route) ?? route)
                .toList(growable: false),
      onUnknownRoute: app.onUnknownRoute == null
          ? null
          : (settings) => _wrapRoute(app.onUnknownRoute!(settings)),
      onNavigationNotification: app.onNavigationNotification,
      navigatorObservers: <NavigatorObserver>[
        ...?app.navigatorObservers,
        _actionNavigatorObserver,
      ],
      builder: app.builder,
      title: app.title,
      onGenerateTitle: app.onGenerateTitle,
      color: app.color,
      theme: app.theme,
      darkTheme: app.darkTheme,
      highContrastTheme: app.highContrastTheme,
      highContrastDarkTheme: app.highContrastDarkTheme,
      themeMode: app.themeMode,
      themeAnimationDuration: app.themeAnimationDuration,
      themeAnimationCurve: app.themeAnimationCurve,
      locale: app.locale,
      localizationsDelegates: app.localizationsDelegates,
      localeListResolutionCallback: app.localeListResolutionCallback,
      localeResolutionCallback: app.localeResolutionCallback,
      supportedLocales: app.supportedLocales,
      debugShowMaterialGrid: app.debugShowMaterialGrid,
      showPerformanceOverlay: app.showPerformanceOverlay,
      checkerboardRasterCacheImages: app.checkerboardRasterCacheImages,
      checkerboardOffscreenLayers: app.checkerboardOffscreenLayers,
      showSemanticsDebugger: app.showSemanticsDebugger,
      debugShowCheckedModeBanner: app.debugShowCheckedModeBanner,
      shortcuts: app.shortcuts,
      actions: app.actions,
      restorationScopeId: app.restorationScopeId,
      scrollBehavior: app.scrollBehavior,
      themeAnimationStyle: app.themeAnimationStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = widget.child;
    if (child is! MaterialApp) {
      throw FlutterError('DuoSafeArea.child must be a MaterialApp.');
    }

    return _DuoSafeAreaScope(
      isIphoneDuo: _isIphoneDuo,
      exception: widget.exception,
      backgroundColor: widget.backgroundColor,
      registry: _actionRegistry,
      deviceWidthState: _deviceWidthState,
      child: _buildMaterialApp(child),
    );
  }
}

class _DuoSafeAreaScope extends InheritedWidget {
  const _DuoSafeAreaScope({
    required this.isIphoneDuo,
    required this.exception,
    required this.backgroundColor,
    required this.registry,
    required this.deviceWidthState,
    required super.child,
  });

  final bool isIphoneDuo;
  final List<Type> exception;
  final Color? backgroundColor;
  final AppActionRegistry registry;
  final DeviceWidthState deviceWidthState;

  Widget wrap(Widget page) {
    return _DuoPageWrapper(
      isIphoneDuo: isIphoneDuo,
      isException: exception.contains(page.runtimeType),
      backgroundColor: backgroundColor,
      actionRegistry: registry,
      deviceWidthState: deviceWidthState,
      page: page,
    );
  }

  @override
  bool updateShouldNotify(_DuoSafeAreaScope oldWidget) {
    return isIphoneDuo != oldWidget.isIphoneDuo ||
        !listEquals(exception, oldWidget.exception) ||
        backgroundColor != oldWidget.backgroundColor ||
        deviceWidthState != oldWidget.deviceWidthState;
  }
}

class _DuoPageWrapper extends StatefulWidget {
  const _DuoPageWrapper({
    required this.isIphoneDuo,
    required this.isException,
    required this.backgroundColor,
    required this.actionRegistry,
    required this.deviceWidthState,
    required this.page,
  });

  final bool isIphoneDuo;
  final bool isException;
  final Color? backgroundColor;
  final AppActionRegistry actionRegistry;
  final DeviceWidthState deviceWidthState;
  final Widget page;

  @override
  State<_DuoPageWrapper> createState() => _DuoPageWrapperState();
}

class _DuoPageWrapperState extends State<_DuoPageWrapper> {
  final DuoBottomNavRegistry _bottomNavRegistry = DuoBottomNavRegistry();
  final GlobalKey _pageContentKey = GlobalKey();

  @override
  void reassemble() {
    _bottomNavRegistry.clear();
    super.reassemble();
  }

  @override
  void dispose() {
    _bottomNavRegistry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    widget.deviceWidthState.updateScreen(width);
    return ListenableBuilder(
      listenable: widget.deviceWidthState,
      builder: (context, _) {
        final Widget actionScopedPage = AppActionScope(
          isIphoneDuo: widget.isIphoneDuo,
          registry: widget.actionRegistry,
          bottomNavRegistry: _bottomNavRegistry,
          deviceWidthState: widget.deviceWidthState,
          child: KeyedSubtree(
            key: _pageContentKey,
            child: widget.page,
          ),
        );
        if (widget.isException) {
          return actionScopedPage;
        }
        if (!widget.isIphoneDuo) {
          return _nonDuoLargeScreenNavigationRail(
            actionScopedPage,
            _bottomNavRegistry,
            isLargeScreen: widget.deviceWidthState.state,
          );
        }
        return _duoToolbarSafeArea(
          actionScopedPage,
          widget.backgroundColor,
          _bottomNavRegistry,
          isSubDisplay: !widget.deviceWidthState.state,
        );
      },
    );
  }
}

const Key _leftSafeAreaBackgroundKey = ValueKey<String>(
  'duoSafeArea.leftBackground',
);
const Key _rightSafeAreaBackgroundKey = ValueKey<String>(
  'duoSafeArea.rightBackground',
);
const Key _verticalBottomNavKey = ValueKey<String>(
  'duoSafeArea.verticalBottomNav',
);
const Key _navigationRailKey = ValueKey<String>(
  'duoSafeArea.navigationRail',
);
const Key _expandedPageChildKey = ValueKey<String>(
  'duoSafeArea.expandedPageChild',
);

Widget _nonDuoLargeScreenNavigationRail(
  Widget child,
  DuoBottomNavRegistry bottomNavRegistry, {
  required bool isLargeScreen,
}) {
  return ListenableBuilder(
    listenable: bottomNavRegistry,
    builder: (context, _) {
      final DuoBottomNavEntry? activeBottomNav =
          isLargeScreen ? bottomNavRegistry.activeEntry : null;
      final int safeIndex = activeBottomNav == null
          ? 0
          : activeBottomNav.selectedIndex.clamp(
              0,
              activeBottomNav.items.length - 1,
            );
      return Row(
        children: <Widget>[
          if (activeBottomNav != null) ...<Widget>[
            NavigationRail(
              key: _navigationRailKey,
              selectedIndex: safeIndex,
              onDestinationSelected: activeBottomNav.onSelected,
              backgroundColor: activeBottomNav.backgroundColor,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: activeBottomNav.selectedItemColor == null
                  ? null
                  : IconThemeData(color: activeBottomNav.selectedItemColor),
              unselectedIconTheme: activeBottomNav.unselectedItemColor == null
                  ? null
                  : IconThemeData(color: activeBottomNav.unselectedItemColor),
              selectedLabelTextStyle: activeBottomNav.selectedItemColor == null
                  ? null
                  : TextStyle(color: activeBottomNav.selectedItemColor),
              unselectedLabelTextStyle:
                  activeBottomNav.unselectedItemColor == null
                      ? null
                      : TextStyle(color: activeBottomNav.unselectedItemColor),
              destinations: <NavigationRailDestination>[
                for (final DuoBottomNavItem item in activeBottomNav.items)
                  NavigationRailDestination(
                    icon: item.icon,
                    selectedIcon: item.selectedIcon,
                    label: Text(item.label ?? item.tooltip ?? ''),
                  ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
          ],
          Expanded(
            key: _expandedPageChildKey,
            child: child,
          ),
        ],
      );
    },
  );
}

Widget _duoToolbarSafeArea(
  Widget child,
  Color? backgroundColor,
  DuoBottomNavRegistry bottomNavRegistry, {
  bool isSubDisplay = false,
}) {
  final Widget safeArea = SafeArea(
    left: true,
    top: false,
    right: true,
    bottom: false,
    child: child,
  );

  return ListenableBuilder(
    listenable: bottomNavRegistry,
    builder: (context, _) {
      final DuoBottomNavEntry? activeBottomNav = bottomNavRegistry.activeEntry;

      if (backgroundColor == null && activeBottomNav == null) {
        return safeArea;
      }

      final EdgeInsets padding = MediaQuery.paddingOf(context);
      final bool isLeftEdge =
          padding.left > padding.right && padding.left > 0;
      final double sideStripWidth = isLeftEdge
          ? padding.left
          : (padding.right > 0 ? padding.right : 68.0);
      // On the sub-display (Outer Display), avoid the corner punch-hole region.
      final double minBottomInset = isSubDisplay ? 112.0 : 16.0;
      final double bottomInset =
          padding.bottom > minBottomInset ? padding.bottom : minBottomInset;

      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (backgroundColor != null && padding.left > 0)
            Positioned(
              key: _leftSafeAreaBackgroundKey,
              left: 0,
              top: 0,
              bottom: 0,
              width: padding.left,
              child: ColoredBox(color: backgroundColor),
            ),
          if (backgroundColor != null && padding.right > 0)
            Positioned(
              key: _rightSafeAreaBackgroundKey,
              right: 0,
              top: 0,
              bottom: 0,
              width: padding.right,
              child: ColoredBox(color: backgroundColor),
            ),
          safeArea,
          if (activeBottomNav != null)
            Positioned(
              key: _verticalBottomNavKey,
              left: isLeftEdge ? 0 : null,
              right: isLeftEdge ? null : 0,
              bottom: bottomInset,
              width: sideStripWidth,
              child: Center(
                child: DuoVerticalBottomNav(entry: activeBottomNav),
              ),
            ),
        ],
      );
    },
  );
}
