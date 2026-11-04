---
name: foldable-ui-duo-tab-bar
description: >-
  Usage and implementation guide for DuoTabBar in foldable_devices_ui. Use when
  adapting Scaffold.bottomNavigationBar (BottomNavigationBar) or
  Scaffold.floatingActionButton (FloatingActionButton) for iPhone Duo and
  large-screen foldable devices (NavigationRail conversion at >= 600px).
---

# DuoTabBar

Source: [`lib/src/widgets/duo_tab_bar.dart`](../../../../lib/src/widgets/duo_tab_bar.dart)

`DuoTabBar` wraps a `BottomNavigationBar` or `FloatingActionButton` inside a `Scaffold` and adapts its presentation based on the device and screen size.

---

## Constructor & Parameters

```dart
const DuoTabBar({
  Key? key,
  bool useIndependence = false,
  required Widget child,
})
```

- **`child`** (`Widget`, required): Supports `BottomNavigationBar` or `FloatingActionButton`.
- **`useIndependence`** (`bool`, default `false`):
  - For `BottomNavigationBar` on iPhone Duo: Enables translucent glass blur (`BackdropFilter` with `sigmaX: 18, sigmaY: 18`) and elevated shadow on [`DuoVerticalBottomNav`](../DuoVerticalBottomNav/SKILL.md).
  - For `FloatingActionButton` on iPhone Duo: Marks the action with `isIndependent: true` when registering `AppAction`.

---

## Behavior Matrix

### 1. When `child` is `BottomNavigationBar`
- **iPhone Duo (Unfolded & Sub-display Folded)**:
  - Extracts `items`, `currentIndex`, `onTap`, `selectedItemColor ?? fixedColor`, `unselectedItemColor`, and `backgroundColor` into a `DuoBottomNavEntry`.
  - Registers the entry into the current page's `DuoBottomNavRegistry` provided by [`DuoSafeArea`](../DuoSafeArea/SKILL.md).
  - Returns `SizedBox.shrink()` in `Scaffold.bottomNavigationBar`, while [`DuoSafeArea`](../DuoSafeArea/SKILL.md) renders [`DuoVerticalBottomNav`](../DuoVerticalBottomNav/SKILL.md) in the side safe-area strip (avoiding the corner punch-hole on the sub-display).
- **Non-Duo Large Screens (`!isIphoneDuo && width >= 600` on Android / `>= 890` on iOS)**:
  - Registers the `DuoBottomNavEntry` into the page's `DuoBottomNavRegistry`.
  - Returns `SizedBox.shrink()` in `Scaffold.bottomNavigationBar`, while [`DuoSafeArea`](../DuoSafeArea/SKILL.md) renders a full-screen standard Flutter `NavigationRail` at the left edge of the page.
- **Non-Duo Small Screens (`!isIphoneDuo && width < 600`)**:
  - Unregisters from `DuoBottomNavRegistry` and renders the original `BottomNavigationBar` at the bottom of the `Scaffold`.

### 2. When `child` is `FloatingActionButton`
- **iPhone Duo (Unfolded & Sub-display Folded)**:
  - Requires `child.child` to be an `Icon`.
  - Rasterizes the `Icon` to PNG bytes and registers an `AppAction` (`role: AppActionRole.primary`, `priority: 80`) into `AppActionRegistry` so it appears in the single native UIKit toolbar capsule.
  - Returns `SizedBox.shrink()` in `Scaffold.floatingActionButton`.
- **Non-Duo Devices (Android Foldables, Tablets, Standard Phones)**:
  - Renders the standard Flutter `FloatingActionButton` in `Scaffold.floatingActionButton`.

---

## Usage Example

```dart
Scaffold(
  appBar: AppBar(
    title: const Text('Home'),
  ),
  body: const Center(child: Text('Content')),
  floatingActionButton: DuoTabBar(
    useIndependence: true,
    child: FloatingActionButton(
      onPressed: _incrementCounter,
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    ),
  ),
  bottomNavigationBar: DuoTabBar(
    child: BottomNavigationBar(
      currentIndex: _tabIndex,
      onTap: (index) => setState(() => _tabIndex = index),
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    ),
  ),
)
```
