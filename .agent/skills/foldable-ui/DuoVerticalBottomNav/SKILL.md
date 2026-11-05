---
name: foldable-ui-duo-vertical-bottom-nav
description: >-
  Usage and implementation guide for DuoVerticalBottomNav, DuoBottomNavEntry,
  and DuoBottomNavItem in foldable_devices_ui. Use when customizing or
  inspecting the vertical pill-shaped bottom navigation bar rendered inside the
  iPhone Duo side safe-area strip.
---

# DuoVerticalBottomNav

Source: [`lib/src/widgets/duo_tab_bar.dart`](../../../../lib/src/widgets/duo_tab_bar.dart)

`DuoVerticalBottomNav` is a Flutter widget that renders a vertical pill-shaped navigation bar (`width: 62pt`, with icon (size 24) + label stacked vertically in each item button) inside the iPhone Duo side safe-area strip.

In standard usage, developers do **not** need to instantiate `DuoVerticalBottomNav` manually—wrapping a `BottomNavigationBar` in [`DuoTabBar`](../DuoTabBar/SKILL.md) inside [`DuoSafeArea`](../DuoSafeArea/SKILL.md) automatically extracts a `DuoBottomNavEntry` and positions `DuoVerticalBottomNav` in the side safe-area strip.

---

## Classes & Properties

### `DuoVerticalBottomNav`

```dart
const DuoVerticalBottomNav({
  Key? key,
  required DuoBottomNavEntry entry,
})
```

### `DuoBottomNavEntry`

```dart
const DuoBottomNavEntry({
  required List<DuoBottomNavItem> items,
  required int selectedIndex,
  required ValueChanged<int>? onSelected,
  bool useIndependence = false,
  bool showSelectedLabels = true,
  bool showUnselectedLabels = true,
  Color? selectedItemColor,
  Color? unselectedItemColor,
  Color? backgroundColor,
})
```

- **`DuoBottomNavEntry.tryFromWidget(Widget child, {bool useIndependence = false})`**:
  Extracts a `DuoBottomNavEntry` when `child` is a non-empty `BottomNavigationBar` (returns `null` for other widgets).

### `DuoBottomNavItem`

```dart
const DuoBottomNavItem({
  required Widget icon,
  required Widget selectedIcon,
  String? label,
  String? tooltip,
})
```

---

## Positioning & Sub-display Punch-Hole Avoidance

When rendered by [`DuoSafeArea`](../DuoSafeArea/SKILL.md) on iPhone Duo:
- Automatically detects whether the system vertical bar strip is on the left (`padding.left > padding.right`) or right edge.
- **Unfolded Inner Display (`DeviceWidthState.state == true`)**: Positioned at `bottom: max(padding.bottom, 16.0)`.
- **Folded Sub-display / Outer Display (`DeviceWidthState.state == false`)**:
  - **Portrait (not landscape)**: Dynamic Island is at the top of the device and does not interfere with the bottom of the vertical bar, so it is positioned at `bottom: max(padding.bottom, 16.0)` (bottom of the screen).
  - **Landscape (`Orientation.landscape`)**: Positioned at `bottom: max(padding.bottom, 112.0)` to avoid colliding with the corner Dynamic Island / camera punch-hole on the sub-display.
- When `entry.useIndependence == true`, applies a frosted glass blur (`BackdropFilter` with `sigmaX: 18, sigmaY: 18`).
