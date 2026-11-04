import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../state/width_state.dart';
import 'duo_tab_bar.dart';

/// The inferred role of a control in the iPhone Duo toolbar.
enum AppActionRole { back, primary, action, destination }

/// A serializable action presented in the native iPhone Duo toolbar.
@immutable
class AppAction {
  const AppAction({
    required this.id,
    required this.role,
    required this.onPressed,
    this.label,
    this.iconBytes,
    this.selectedIconBytes,
    this.priority = 0,
    this.isEnabled = true,
    this.isSelected = false,
    this.isIndependent = false,
  });

  final String id;
  final AppActionRole role;
  final String? label;
  final Uint8List? iconBytes;
  final Uint8List? selectedIconBytes;
  final int priority;
  final bool isEnabled;
  final bool isSelected;
  final bool isIndependent;
  final VoidCallback onPressed;

  Map<String, Object?> toPlatformMap() => <String, Object?>{
    'id': id,
    'role': role.name,
    'label': label,
    'icon': iconBytes,
    'selectedIcon': selectedIconBytes,
    'priority': priority,
    'enabled': isEnabled,
    'selected': isSelected,
    'independent': isIndependent,
  };
}

class _ActionSource {
  const _ActionSource({
    required this.route,
    required this.navigator,
    required this.actions,
    this.context,
  });

  final ModalRoute<dynamic>? route;
  final NavigatorState? navigator;
  final List<AppAction> actions;
  final BuildContext? context;
}

/// Collects actions from visible routes and sends updates to the native host.
class AppActionRegistry extends ChangeNotifier {
  final Map<Object, _ActionSource> _sources = <Object, _ActionSource>{};
  NavigatorState? _rootNavigator;
  bool _notificationScheduled = false;
  bool _disposed = false;

  @visibleForTesting
  int get registeredSourceCount => _sources.length;

  List<_ActionSource> get _activeSources => _sources.values
      .where(
        (source) =>
            (source.context == null || source.context!.mounted) &&
            (source.route == null || source.route!.isCurrent),
      )
      .toList(growable: false);

  List<AppAction> get activeActions => <AppAction>[
    for (final _ActionSource source in _activeSources) ...source.actions,
  ];

  bool get canPop {
    final List<_ActionSource> sources = _activeSources;
    for (var i = sources.length - 1; i >= 0; i--) {
      final NavigatorState? navigator = sources[i].navigator;
      if (navigator != null && navigator.mounted) return navigator.canPop();
    }
    final NavigatorState? navigator = _rootNavigator;
    return navigator != null && navigator.mounted && navigator.canPop();
  }

  void register({
    required Object sourceId,
    required ModalRoute<dynamic>? route,
    required NavigatorState? navigator,
    required List<AppAction> actions,
    BuildContext? context,
  }) {
    _sources[sourceId] = _ActionSource(
      route: route,
      navigator: navigator,
      actions: actions,
      context: context,
    );
    _notifyAfterFrame();
  }

  void unregister(Object sourceId) {
    if (_sources.remove(sourceId) != null) _notifyAfterFrame();
  }

  void clear() {
    if (_sources.isEmpty) return;
    _sources.clear();
    _notifyAfterFrame();
  }

  void updateNavigator(NavigatorState? navigator) {
    _rootNavigator = navigator;
    _notifyAfterFrame();
  }

  void invoke(String actionId) {
    for (final AppAction action in activeActions) {
      if (action.id == actionId && action.isEnabled) {
        action.onPressed();
        return;
      }
    }
    if (actionId == 'duo.autoBack') {
      final List<_ActionSource> sources = _activeSources;
      for (var i = sources.length - 1; i >= 0; i--) {
        final NavigatorState? navigator = sources[i].navigator;
        if (navigator != null && navigator.mounted && navigator.canPop()) {
          navigator.maybePop();
          return;
        }
      }
      final NavigatorState? navigator = _rootNavigator;
      if (navigator != null && navigator.mounted) navigator.maybePop();
    }
  }

  void _notifyAfterFrame() {
    if (_disposed || _notificationScheduled) return;
    _notificationScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notificationScheduled = false;
      if (!_disposed) notifyListeners();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _disposed = true;
    _sources.clear();
    super.dispose();
  }
}

/// Makes a toolbar action registry available below [DuoSafeArea].
class AppActionScope extends InheritedWidget {
  const AppActionScope({
    super.key,
    required this.isIphoneDuo,
    required this.registry,
    this.bottomNavRegistry,
    this.deviceWidthState,
    @visibleForTesting this.iconRasterizer,
    required super.child,
  });

  final bool isIphoneDuo;
  final AppActionRegistry registry;
  final DuoBottomNavRegistry? bottomNavRegistry;
  final DeviceWidthState? deviceWidthState;

  /// Returns true when running on an iPhone Duo device (in both folded/closed
  /// outer display and unfolded/open inner display states).
  bool get isEffectiveDuo => isIphoneDuo;

  /// Returns true when the current screen width meets the large-screen threshold
  /// (`width >= 600` on Android/other platforms, `width >= 890` on iOS).
  bool get isLargeScreen => deviceWidthState?.state ?? false;

  /// Returns true when bottom navigation should be relocated (to the vertical bar
  /// on iPhone Duo, or to a [NavigationRail] on non-Duo large screens).
  bool get shouldRelocateBottomNav => isIphoneDuo || isLargeScreen;

  @visibleForTesting
  final Future<Uint8List?> Function(BuildContext context, Widget icon)?
  iconRasterizer;

  /// Renders a widget icon to PNG bytes using the inherited theme and media query,
  /// or delegates to [iconRasterizer] when set (e.g. during testing).
  Future<Uint8List?> renderIcon(BuildContext context, Widget icon) {
    final rasterizer = iconRasterizer;
    if (rasterizer != null) {
      return rasterizer(context, icon);
    }
    final environment = _IconRenderEnvironment(
      iconTheme: IconTheme.of(context),
      fallbackColor: Theme.of(context).colorScheme.onSurface,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      pixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    return _rasterizeIcon(icon, environment);
  }

  static AppActionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppActionScope>();

  @override
  bool updateShouldNotify(AppActionScope oldWidget) =>
      isIphoneDuo != oldWidget.isIphoneDuo ||
      registry != oldWidget.registry ||
      bottomNavRegistry != oldWidget.bottomNavRegistry ||
      deviceWidthState != oldWidget.deviceWidthState ||
      iconRasterizer != oldWidget.iconRasterizer;
}

/// Observes the MaterialApp Navigator so the native back item follows push/pop.
class AppActionNavigatorObserver extends NavigatorObserver {
  AppActionNavigatorObserver(this.registry);

  final AppActionRegistry registry;

  void _update() => registry.updateNavigator(navigator);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _update();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _update();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _update();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _update();
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    super.didChangeTop(topRoute, previousTopRoute);
    _update();
  }
}

/// Moves supported controls into the iPhone Duo toolbar.
///
/// On other platforms, the original widgets remain at this location. Supported
/// children are [IconButton], [BackButton], [FloatingActionButton],
/// [BottomNavigationBar], and [NavigationBar].
class ToolBar extends StatefulWidget {
  const ToolBar({super.key, required this.child});

  /// Controls to publish to the Duo toolbar, in display order.
  final List<Widget> child;

  @override
  State<ToolBar> createState() => _ToolBarState();
}

class _ToolBarState extends State<ToolBar> {
  final Object _sourceId = Object();
  int _generation = 0;
  AppActionRegistry? _registeredRegistry;
  bool _isIphoneDuo = false;
  List<Widget> _unsupported = const <Widget>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshRegistration();
  }

  @override
  void didUpdateWidget(covariant ToolBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshRegistration();
  }

  @override
  void reassemble() {
    super.reassemble();
    _refreshRegistration();
  }

  void _refreshRegistration() {
    final int generation = ++_generation;
    final AppActionScope? scope = AppActionScope.maybeOf(context);
    final AppActionRegistry? previousRegistry = _registeredRegistry;
    _registeredRegistry = scope?.registry;
    if (previousRegistry != null && previousRegistry != scope?.registry) {
      previousRegistry.unregister(_sourceId);
    }

    _isIphoneDuo = scope?.isEffectiveDuo ?? false;
    if (scope == null || !_isIphoneDuo) {
      scope?.registry.unregister(_sourceId);
      _unsupported = widget.child;
      return;
    }

    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    final NavigatorState? navigator = Navigator.maybeOf(context);

    _buildActions(
      context,
      widget.child,
      _sourceId,
      iconRasterizer: scope.iconRasterizer,
    ).then((result) {
      if (!mounted || generation != _generation) return;
      _unsupported = result.unsupported;
      if (result.actions.isEmpty) {
        scope.registry.unregister(_sourceId);
      } else {
        scope.registry.register(
          sourceId: _sourceId,
          route: route,
          navigator: navigator,
          actions: result.actions,
          context: context,
        );
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _registeredRegistry?.unregister(_sourceId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppActionScope? scope = AppActionScope.maybeOf(context);
    if (scope?.isEffectiveDuo != true) {
      return _fallback(widget.child);
    }
    if (_unsupported.isNotEmpty) return _fallback(_unsupported);
    return const SizedBox.shrink();
  }

  Widget _fallback(List<Widget> widgets) {
    if (widgets.isEmpty) return const SizedBox.shrink();
    if (widgets.length == 1) return widgets.single;
    return Row(mainAxisSize: MainAxisSize.min, children: widgets);
  }
}

class _ActionBuildResult {
  const _ActionBuildResult(this.actions, this.unsupported);

  final List<AppAction> actions;
  final List<Widget> unsupported;
}

class _IconRenderEnvironment {
  const _IconRenderEnvironment({
    required this.iconTheme,
    required this.fallbackColor,
    required this.textDirection,
    required this.textScaler,
    required this.pixelRatio,
  });

  final IconThemeData iconTheme;
  final Color fallbackColor;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final double pixelRatio;
}

Future<_ActionBuildResult> _buildActions(
  BuildContext context,
  List<Widget> children,
  Object sourceId, {
  Future<Uint8List?> Function(BuildContext context, Widget icon)?
  iconRasterizer,
}) async {
  final _IconRenderEnvironment environment = _IconRenderEnvironment(
    iconTheme: IconTheme.of(context),
    fallbackColor: Theme.of(context).colorScheme.onSurface,
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    pixelRatio: MediaQuery.devicePixelRatioOf(context),
  );
  final List<AppAction> actions = <AppAction>[];
  final List<Widget> unsupported = <Widget>[];
  final NavigatorState? navigator = Navigator.maybeOf(context);
  final ModalRoute<dynamic>? route = ModalRoute.of(context);
  final bool canPop = route?.canPop ?? navigator?.canPop() ?? false;
  var index = 0;

  Future<Uint8List?> renderIcon(Widget icon) {
    final rasterizer = iconRasterizer;
    return rasterizer == null
        ? _rasterizeIcon(icon, environment)
        : rasterizer(context, icon);
  }

  Future<void> addAction({
    required AppActionRole role,
    required String? label,
    required Widget icon,
    required VoidCallback? onPressed,
    int priority = 0,
    bool enabled = true,
    bool selected = false,
    Widget? selectedIcon,
  }) async {
    final Uint8List? iconBytes = await renderIcon(icon);
    final Uint8List? selectedIconBytes = selectedIcon == null
        ? null
        : await renderIcon(selectedIcon);
    if (iconBytes == null) return;
    actions.add(
      AppAction(
        id: '${identityHashCode(sourceId)}:$index',
        role: role,
        label: label,
        iconBytes: iconBytes,
        selectedIconBytes: selectedIconBytes,
        priority: priority,
        isEnabled: enabled && onPressed != null,
        isSelected: selected,
        onPressed: onPressed ?? () {},
      ),
    );
    index++;
  }

  for (final Widget child in children) {
    if (child is _AppBarBackAction) {
      if (child.onPressed == null && !canPop) continue;
      await addAction(
        role: AppActionRole.back,
        label: child.tooltip ?? 'Back',
        icon: Icon(child.icon, color: child.color),
        onPressed: child.onPressed ?? () => navigator?.maybePop(),
        priority: 100,
      );
    } else if (child is BackButton) {
      if (child.onPressed == null && !canPop) continue;
      await addAction(
        role: AppActionRole.back,
        label: child.tooltip ?? 'Back',
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: child.onPressed ?? () => navigator?.maybePop(),
        priority: 100,
      );
    } else if (child is IconButton) {
      final Icon? icon = child.icon is Icon ? child.icon as Icon : null;
      if (icon == null) {
        unsupported.add(child);
        continue;
      }
      await addAction(
        role: AppActionRole.action,
        label: child.tooltip,
        icon: icon,
        onPressed: child.onPressed,
        priority: 50,
      );
    } else if (child is FloatingActionButton) {
      final Icon? icon = child.child is Icon ? child.child as Icon : null;
      if (icon == null) {
        unsupported.add(child);
        continue;
      }
      await addAction(
        role: AppActionRole.primary,
        label: child.tooltip,
        icon: icon,
        onPressed: child.onPressed,
        priority: 80,
      );
    } else if (child is BottomNavigationBar) {
      final bool iconsSupported = child.items.every(
        (item) => item.icon is Icon && item.activeIcon is Icon,
      );
      if (!iconsSupported) {
        unsupported.add(child);
        continue;
      }
      for (var itemIndex = 0; itemIndex < child.items.length; itemIndex++) {
        final BottomNavigationBarItem item = child.items[itemIndex];
        final bool selected = itemIndex == child.currentIndex;
        await addAction(
          role: AppActionRole.destination,
          label: item.tooltip ?? item.label,
          icon: (selected ? item.activeIcon : item.icon) as Icon,
          selectedIcon: item.activeIcon as Icon,
          onPressed: child.onTap == null ? null : () => child.onTap!(itemIndex),
          priority: 70,
          selected: selected,
          enabled: child.onTap != null,
        );
      }
    } else if (child is NavigationBar) {
      final List<NavigationDestination> destinations = child.destinations
          .whereType<NavigationDestination>()
          .toList(growable: false);
      if (destinations.length != child.destinations.length ||
          destinations.any(
            (destination) =>
                destination.icon is! Icon || destination.selectedIcon is! Icon,
          )) {
        unsupported.add(child);
        continue;
      }
      for (var itemIndex = 0; itemIndex < destinations.length; itemIndex++) {
        final NavigationDestination destination = destinations[itemIndex];
        final bool selected = itemIndex == child.selectedIndex;
        await addAction(
          role: AppActionRole.destination,
          label: destination.tooltip ?? destination.label,
          icon:
              (selected ? destination.selectedIcon : destination.icon) as Icon,
          selectedIcon: destination.selectedIcon as Icon,
          onPressed: child.onDestinationSelected == null
              ? null
              : () => child.onDestinationSelected!(itemIndex),
          priority: 70,
          selected: selected,
        );
      }
    } else {
      unsupported.add(child);
    }
  }

  return _ActionBuildResult(actions, unsupported);
}

Future<Uint8List?> _rasterizeIcon(
  Widget widget,
  _IconRenderEnvironment environment,
) async {
  if (widget is! Icon || widget.icon == null) return null;
  final IconThemeData iconTheme = environment.iconTheme;
  final double nominalSize = widget.size ?? iconTheme.size ?? 24;
  final bool applyTextScaling =
      widget.applyTextScaling ?? iconTheme.applyTextScaling ?? false;
  final double logicalSize = applyTextScaling
      ? environment.textScaler.scale(nominalSize)
      : nominalSize;
  final double pixelRatio = environment.pixelRatio;
  final IconData iconData = widget.icon!;
  Color? iconColor =
      widget.color ?? iconTheme.color ?? environment.fallbackColor;
  final double opacity = iconTheme.opacity ?? 1;
  if (opacity != 1) {
    iconColor = iconColor.withValues(alpha: iconColor.a * opacity);
  }
  ui.Paint? foreground;
  if (widget.blendMode != null) {
    foreground = ui.Paint()
      ..blendMode = widget.blendMode!
      ..color = iconColor;
    iconColor = null;
  }
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        inherit: false,
        fontVariations: <ui.FontVariation>[
          if ((widget.fill ?? iconTheme.fill) case final double fill)
            ui.FontVariation('FILL', fill),
          if ((widget.weight ?? iconTheme.weight) case final double weight)
            ui.FontVariation('wght', weight),
          if ((widget.grade ?? iconTheme.grade) case final double grade)
            ui.FontVariation('GRAD', grade),
          if ((widget.opticalSize ?? iconTheme.opticalSize)
              case final double opticalSize)
            ui.FontVariation('opsz', opticalSize),
        ],
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        fontFamilyFallback: iconData.fontFamilyFallback,
        fontWeight: widget.fontWeight,
        fontSize: logicalSize,
        color: iconColor,
        foreground: foreground,
        shadows: widget.shadows ?? iconTheme.shadows,
        height: 1,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    ),
    textDirection: environment.textDirection,
  )..layout();
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  canvas.scale(pixelRatio);
  if (iconData.matchTextDirection &&
      environment.textDirection == TextDirection.rtl) {
    canvas.translate(logicalSize, 0);
    canvas.scale(-1, 1);
  }
  painter.paint(
    canvas,
    ui.Offset(
      (logicalSize - painter.width) / 2,
      (logicalSize - painter.height) / 2,
    ),
  );
  final ui.Image image = await recorder.endRecording().toImage(
    (logicalSize * pixelRatio).ceil(),
    (logicalSize * pixelRatio).ceil(),
  );
  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (data == null) return null;
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

Future<Uint8List?> rasterizeDefaultToolbarIcon(
  Widget widget, {
  Color color = const Color(0xFF1C1C1E),
  double pixelRatio = 3.0,
}) {
  return _rasterizeIcon(
    widget,
    _IconRenderEnvironment(
      iconTheme: IconThemeData(color: color, size: 24),
      fallbackColor: color,
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      pixelRatio: pixelRatio,
    ),
  );
}

/// A back button that moves into the iPhone Duo toolbar when hosted by
/// [DuoSafeArea]. Set the containing [AppBar.automaticallyImplyLeading] to
/// false to avoid also displaying Flutter's implicit back button.
class AppBarBackButtonWidget extends StatelessWidget {
  const AppBarBackButtonWidget({
    super.key,
    this.icon = Icons.arrow_back_ios_new,
    this.color,
    this.tooltip = 'Back',
    this.onPressed,
  });

  final IconData icon;
  final Color? color;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ToolBar(
      child: <Widget>[
        _AppBarBackAction(
          icon: icon,
          color: color,
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      ],
    );
  }
}

class _AppBarBackAction extends StatelessWidget {
  const _AppBarBackAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color? color;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    color: color,
    onPressed: onPressed ?? () => Navigator.maybePop(context),
    icon: Icon(icon, color: color),
  );
}
