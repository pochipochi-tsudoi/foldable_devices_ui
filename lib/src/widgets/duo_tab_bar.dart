import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'app_action.dart';

/// A single navigation item displayed in the iPhone Duo vertical bottom navigation bar.
@immutable
class DuoBottomNavItem {
  const DuoBottomNavItem({
    required this.icon,
    required this.selectedIcon,
    this.label,
    this.tooltip,
  });

  final Widget icon;
  final Widget selectedIcon;
  final String? label;
  final String? tooltip;
}

/// Configuration for a Flutter-rendered vertical bottom navigation bar on iPhone Duo.
@immutable
class DuoBottomNavEntry {
  const DuoBottomNavEntry({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.useIndependence = false,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.backgroundColor,
    this.showSelectedLabels = true,
    this.showUnselectedLabels = true,
  });

  final List<DuoBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;
  final bool useIndependence;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final Color? backgroundColor;
  final bool showSelectedLabels;
  final bool showUnselectedLabels;

  /// Extracts a [DuoBottomNavEntry] from a [BottomNavigationBar].
  static DuoBottomNavEntry? tryFromWidget(
    Widget child, {
    bool useIndependence = false,
  }) {
    if (child is BottomNavigationBar) {
      if (child.items.isEmpty) return null;
      final List<DuoBottomNavItem> items = <DuoBottomNavItem>[
        for (final BottomNavigationBarItem item in child.items)
          DuoBottomNavItem(
            icon: item.icon,
            selectedIcon: item.activeIcon,
            label: item.label,
            tooltip: item.tooltip ?? item.label,
          ),
      ];
      final int clampedIndex = child.currentIndex.clamp(0, items.length - 1);
      return DuoBottomNavEntry(
        items: items,
        selectedIndex: clampedIndex,
        onSelected: child.onTap == null
            ? null
            : (int index) {
                child.onTap?.call(index);
                DuoTabBar.notifyTabSelected(index);
              },
        useIndependence: useIndependence,
        selectedItemColor: child.selectedItemColor ?? child.fixedColor,
        unselectedItemColor: child.unselectedItemColor,
        backgroundColor: child.backgroundColor,
        showSelectedLabels: child.showSelectedLabels ?? true,
        showUnselectedLabels: child.showUnselectedLabels ?? true,
      );
    }
    return null;
  }
}

class _BottomNavSource {
  const _BottomNavSource({
    required this.route,
    required this.entry,
    this.context,
  });

  final ModalRoute<dynamic>? route;
  final DuoBottomNavEntry entry;
  final BuildContext? context;
}

/// Collects Flutter bottom navigation bars from active routes to present them
/// in the iPhone Duo vertical side bar region.
class DuoBottomNavRegistry extends ChangeNotifier {
  final Map<Object, _BottomNavSource> _sources = <Object, _BottomNavSource>{};
  bool _notificationScheduled = false;
  bool _disposed = false;

  @visibleForTesting
  int get registeredSourceCount => _sources.length;

  List<_BottomNavSource> get _activeSources => _sources.values
      .where((source) => source.context == null || source.context!.mounted)
      .toList(growable: false);

  /// The active bottom navigation entry for this page, if any.
  DuoBottomNavEntry? get activeEntry {
    final List<_BottomNavSource> active = _activeSources;
    if (active.isEmpty) return null;
    return active.last.entry;
  }

  /// Returns the registered entry matching [route].
  DuoBottomNavEntry? entryForRoute(ModalRoute<dynamic>? route) {
    for (final _BottomNavSource source in _sources.values.toList().reversed) {
      if (source.context != null && !source.context!.mounted) continue;
      if (source.route == route) {
        return source.entry;
      }
    }
    return activeEntry;
  }

  void register({
    required Object sourceId,
    required ModalRoute<dynamic>? route,
    required DuoBottomNavEntry entry,
    BuildContext? context,
  }) {
    _sources[sourceId] = _BottomNavSource(
      route: route,
      entry: entry,
      context: context,
    );
    _notifyAfterFrame();
  }

  void unregister(Object sourceId) {
    if (_sources.remove(sourceId) != null) {
      _notifyAfterFrame();
    }
  }

  void clear() {
    if (_sources.isEmpty) return;
    _sources.clear();
    _notifyAfterFrame();
  }

  void notifyRouteChanged() {
    _notifyAfterFrame();
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

/// Renders the relocated Flutter bottom navigation bar vertically inside the
/// iPhone Duo side safe-area strip.
class DuoVerticalBottomNav extends StatelessWidget {
  const DuoVerticalBottomNav({
    super.key,
    required this.entry,
  });

  final DuoBottomNavEntry entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    final Color selectedColor =
        entry.selectedItemColor ?? colorScheme.primary;
    final Color unselectedColor =
        entry.unselectedItemColor ??
        (isDark ? Colors.white70 : Colors.black87);
    final Color baseSurfaceColor =
        entry.backgroundColor ??
        (isDark ? const Color(0xFF2C2C2E) : Colors.white);
    final Color surfaceColor = entry.useIndependence
        ? baseSurfaceColor.withValues(alpha: isDark ? 0.78 : 0.88)
        : baseSurfaceColor.withValues(alpha: isDark ? 0.90 : 0.95);
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.10);

    Widget pillContent = Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 5),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(31),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: entry.useIndependence ? 0.14 : 0.06,
            ),
            blurRadius: entry.useIndependence ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < entry.items.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 12),
              _DuoVerticalBottomNavItemButton(
                item: entry.items[i],
                isSelected: i == entry.selectedIndex,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                showLabel: i == entry.selectedIndex
                    ? entry.showSelectedLabels
                    : entry.showUnselectedLabels,
                onTap: entry.onSelected == null
                    ? null
                    : () => entry.onSelected!(i),
              ),
            ],
          ],
        ),
      ),
    );

    if (entry.useIndependence) {
      pillContent = ClipRRect(
        borderRadius: BorderRadius.circular(31),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: pillContent,
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: pillContent,
    );
  }
}

class _DuoVerticalBottomNavItemButton extends StatelessWidget {
  const _DuoVerticalBottomNavItemButton({
    required this.item,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.showLabel,
    required this.onTap,
  });

  final DuoBottomNavItem item;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final bool showLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget iconWidget = isSelected ? item.selectedIcon : item.icon;
    final String? labelText = item.label;
    final String? tooltipText = item.tooltip ?? labelText;
    final Color activeColor = isSelected ? selectedColor : unselectedColor;
    final bool hasVisibleLabel =
        showLabel && labelText != null && labelText.isNotEmpty;

    Widget button = Semantics(
      label: tooltipText,
      selected: isSelected,
      button: true,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 52,
          padding: EdgeInsets.symmetric(
            vertical: hasVisibleLabel ? 9 : 11,
            horizontal: 4,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconTheme.merge(
                data: IconThemeData(
                  color: activeColor,
                  size: 24,
                ),
                child: iconWidget,
              ),
              if (hasVisibleLabel) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  labelText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.15,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: activeColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (tooltipText != null && tooltipText.isNotEmpty) {
      button = Tooltip(
        message: tooltipText,
        child: button,
      );
    }

    return button;
  }
}

/// A tab bar / floating action wrapper for iPhone Duo and foldable devices.
///
/// - On iPhone Duo ([isEffectiveDuo] is true, in both folded and unfolded states):
///   - If [child] is a [BottomNavigationBar], moves the Flutter bottom navigation
///     bar into the vertical bar region at the side of the screen.
///   - If [child] is a [FloatingActionButton], integrates it into the native iOS
///     system bar as a primary/independent action.
/// - On non-iPhone Duo large screens (e.g. Android foldables and tablets when
///   `DeviceWidthState.state` is true):
///   - If [child] is a [BottomNavigationBar], converts it into a leading
///     [NavigationRail].
/// - In all other cases (small screens outside iPhone Duo):
///   - Renders [child] directly as a standard Flutter widget.
class DuoTabBar extends StatefulWidget {
  const DuoTabBar({
    super.key,
    this.useIndependence = false,
    required this.child,
  });

  /// Controls whether the controls are presented as an independent floating component.
  final bool useIndependence;

  /// The child navigation widget to host (e.g. [BottomNavigationBar] or [FloatingActionButton]).
  final Widget child;

  static final List<void Function(int)> _listeners = <void Function(int)>[];

  /// Called when a tab item is selected.
  static void notifyTabSelected(int index) {
    for (final listener in List<void Function(int)>.from(_listeners)) {
      listener(index);
    }
  }

  @override
  State<DuoTabBar> createState() => _DuoTabBarState();
}

class _DuoTabBarState extends State<DuoTabBar> {
  final Object _sourceId = Object();
  int _generation = 0;
  AppActionRegistry? _registeredActionRegistry;
  DuoBottomNavRegistry? _registeredBottomNavRegistry;
  bool _isEffectiveDuo = false;
  bool _shouldRelocateBottomNav = false;

  @override
  void initState() {
    super.initState();
    DuoTabBar._listeners.add(_onTabSelected);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant DuoTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refresh();
  }

  @override
  void reassemble() {
    super.reassemble();
    _refresh();
  }

  @override
  void dispose() {
    DuoTabBar._listeners.remove(_onTabSelected);
    _registeredActionRegistry?.unregister(_sourceId);
    _registeredBottomNavRegistry?.unregister(_sourceId);
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (!mounted) return;
    final Widget child = widget.child;
    if (child is BottomNavigationBar) {
      child.onTap?.call(index);
    }
  }

  void _refresh() {
    final int generation = ++_generation;
    final AppActionScope? scope = AppActionScope.maybeOf(context);

    final AppActionRegistry? previousActionRegistry = _registeredActionRegistry;
    _registeredActionRegistry = scope?.registry;
    if (previousActionRegistry != null &&
        previousActionRegistry != scope?.registry) {
      previousActionRegistry.unregister(_sourceId);
    }

    final DuoBottomNavRegistry? previousBottomNavRegistry =
        _registeredBottomNavRegistry;
    _registeredBottomNavRegistry = scope?.bottomNavRegistry;
    if (previousBottomNavRegistry != null &&
        previousBottomNavRegistry != scope?.bottomNavRegistry) {
      previousBottomNavRegistry.unregister(_sourceId);
    }

    final bool isEffective = scope?.isEffectiveDuo ?? false;
    final bool shouldRelocateBottomNav =
        scope?.shouldRelocateBottomNav ?? false;
    final bool flagsChanged =
        _isEffectiveDuo != isEffective ||
        _shouldRelocateBottomNav != shouldRelocateBottomNav;
    _isEffectiveDuo = isEffective;
    _shouldRelocateBottomNav = shouldRelocateBottomNav;

    if (scope == null || (!isEffective && !shouldRelocateBottomNav)) {
      scope?.registry.unregister(_sourceId);
      scope?.bottomNavRegistry?.unregister(_sourceId);
      if (flagsChanged) setState(() {});
      return;
    }

    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    final NavigatorState? navigator = Navigator.maybeOf(context);
    final Widget child = widget.child;

    // BottomNavigationBar is relocated in Flutter
    // (vertical side bar on iPhone Duo, or NavigationRail on non-Duo large screens).
    final DuoBottomNavEntry? bottomNavEntry = DuoBottomNavEntry.tryFromWidget(
      child,
      useIndependence: widget.useIndependence,
    );
    if (bottomNavEntry != null) {
      scope.registry.unregister(_sourceId);
      if (shouldRelocateBottomNav) {
        scope.bottomNavRegistry?.register(
          sourceId: _sourceId,
          route: route,
          entry: bottomNavEntry,
          context: context,
        );
      } else {
        scope.bottomNavRegistry?.unregister(_sourceId);
      }
      if (flagsChanged) setState(() {});
      return;
    }

    // FloatingActionButton keeps its native implementation only on iPhone Duo.
    scope.bottomNavRegistry?.unregister(_sourceId);
    if (!isEffective) {
      scope.registry.unregister(_sourceId);
      if (flagsChanged) setState(() {});
      return;
    }
    if (child is FloatingActionButton) {
      final BuildContext currentContext = context;
      Future<Uint8List?> renderIcon(Widget icon) =>
          scope.renderIcon(currentContext, icon);

      _buildFabAppAction(
        _sourceId,
        child,
        widget.useIndependence,
        renderIcon,
      ).then((action) {
        if (!mounted || generation != _generation) return;
        if (action == null) {
          scope.registry.unregister(_sourceId);
        } else {
          scope.registry.register(
            sourceId: _sourceId,
            route: route,
            navigator: navigator,
            actions: <AppAction>[action],
            context: context,
          );
        }
        setState(() {});
      });
    } else {
      scope.registry.unregister(_sourceId);
      setState(() {});
    }
  }

  Future<AppAction?> _buildFabAppAction(
    Object sourceId,
    FloatingActionButton child,
    bool useIndependence,
    Future<Uint8List?> Function(Widget icon) renderIcon,
  ) async {
    final Icon? icon = child.child is Icon ? child.child as Icon : null;
    if (icon == null) return null;
    final Uint8List? iconBytes = await renderIcon(icon);
    if (iconBytes == null) return null;
    return AppAction(
      id: '${identityHashCode(sourceId)}:0',
      role: AppActionRole.primary,
      label: child.tooltip,
      iconBytes: iconBytes,
      priority: 80,
      isEnabled: child.onPressed != null,
      isIndependent: useIndependence,
      onPressed: child.onPressed ?? () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppActionScope? scope = AppActionScope.maybeOf(context);
    final DuoBottomNavEntry? bottomNavEntry = DuoBottomNavEntry.tryFromWidget(
      widget.child,
      useIndependence: widget.useIndependence,
    );
    if (bottomNavEntry != null) {
      if (!_shouldRelocateBottomNav) {
        return widget.child;
      }
      if (scope?.bottomNavRegistry != null) {
        return const SizedBox.shrink();
      }
      if (_isEffectiveDuo) {
        return DuoVerticalBottomNav(entry: bottomNavEntry);
      }
      return NavigationRail(
        selectedIndex: bottomNavEntry.selectedIndex.clamp(
          0,
          bottomNavEntry.items.length - 1,
        ),
        onDestinationSelected: bottomNavEntry.onSelected,
        backgroundColor: bottomNavEntry.backgroundColor,
        labelType: NavigationRailLabelType.all,
        destinations: <NavigationRailDestination>[
          for (final DuoBottomNavItem item in bottomNavEntry.items)
            NavigationRailDestination(
              icon: item.icon,
              selectedIcon: item.selectedIcon,
              label: Text(item.label ?? item.tooltip ?? ''),
            ),
        ],
      );
    }
    if (!_isEffectiveDuo) {
      return widget.child;
    }
    return const SizedBox.shrink();
  }
}
