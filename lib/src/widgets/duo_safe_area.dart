import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../platform/duo_device_info.dart';

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
  bool _isIphoneDuo = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceType();
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
  }

  Widget _wrapPage(Widget page) {
    if (!_isIphoneDuo || widget.exception.contains(page.runtimeType)) {
      return page;
    }
    return _duoToolbarSafeArea(page, widget.backgroundColor);
  }

  Route<dynamic>? _wrapRoute(Route<dynamic>? route) {
    if (!_isIphoneDuo || route is! MaterialPageRoute<dynamic>) {
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
      navigatorObservers: app.navigatorObservers ?? const <NavigatorObserver>[],
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
      child: _buildMaterialApp(child),
    );
  }
}

class _DuoSafeAreaScope extends InheritedWidget {
  const _DuoSafeAreaScope({
    required this.isIphoneDuo,
    required this.exception,
    required this.backgroundColor,
    required super.child,
  });

  final bool isIphoneDuo;
  final List<Type> exception;
  final Color? backgroundColor;

  Widget wrap(Widget page) {
    if (!isIphoneDuo || exception.contains(page.runtimeType)) return page;
    return _duoToolbarSafeArea(page, backgroundColor);
  }

  @override
  bool updateShouldNotify(_DuoSafeAreaScope oldWidget) {
    return isIphoneDuo != oldWidget.isIphoneDuo ||
        !listEquals(exception, oldWidget.exception) ||
        backgroundColor != oldWidget.backgroundColor;
  }
}

const Key _leftSafeAreaBackgroundKey = ValueKey<String>(
  'duoSafeArea.leftBackground',
);
const Key _rightSafeAreaBackgroundKey = ValueKey<String>(
  'duoSafeArea.rightBackground',
);

Widget _duoToolbarSafeArea(Widget child, Color? backgroundColor) {
  final Widget safeArea = SafeArea(
    left: true,
    top: false,
    right: true,
    bottom: false,
    child: child,
  );

  if (backgroundColor == null) return safeArea;

  return Builder(
    builder: (context) {
      final EdgeInsets padding = MediaQuery.paddingOf(context);
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (padding.left > 0)
            Positioned(
              key: _leftSafeAreaBackgroundKey,
              left: 0,
              top: 0,
              bottom: 0,
              width: padding.left,
              child: ColoredBox(color: backgroundColor),
            ),
          if (padding.right > 0)
            Positioned(
              key: _rightSafeAreaBackgroundKey,
              right: 0,
              top: 0,
              bottom: 0,
              width: padding.right,
              child: ColoredBox(color: backgroundColor),
            ),
          safeArea,
        ],
      );
    },
  );
}
