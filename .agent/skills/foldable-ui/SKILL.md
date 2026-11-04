---
name: foldable-ui
description: >-
  Guide and widget reference for the foldable_devices_ui Flutter package.
  Use this skill when building or modifying UI for foldable devices (iPhone Duo,
  Android foldables like Pixel Fold / Galaxy Z Fold, and large-screen tablets),
  including DuoSafeArea, DuoTabBar, ToolBar, AppBarBackButtonWidget,
  DuoVerticalBottomNav, DeviceWidth, and DeviceAngle.
---

# foldable_devices_ui Skill Reference

`foldable_devices_ui` provides adaptive layout and navigation widgets for foldable devices across iOS (iPhone Duo `iPhone19,4`) and Android (foldables and tablets).

Import the package via:

```dart
import 'package:foldable_devices_ui/foldable_devices_ui.dart';
```

---

## Architecture & Platform Behavior Overview

| Platform / State | Screen Threshold (`DeviceWidthState`) | `DuoSafeArea` Behavior | `DuoTabBar` (`BottomNavigationBar`) | `DuoTabBar` (`FloatingActionButton`) | `ToolBar` & `AppBarBackButtonWidget` |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **iPhone Duo (Unfolded)** | `width >= 890` (`Platform.isIOS`) | Applies left/right `SafeArea` + side `backgroundColor` strips | Relocates to side strip as [`DuoVerticalBottomNav`](./DuoVerticalBottomNav/SKILL.md) (`bottom: 16pt`) | Moves into native UIKit toolbar | Moves into single native UIKit toolbar (multiple actions grouped into native `UIMenu`) |
| **iPhone Duo (Sub-display / Folded)** | `width < 890` (`Platform.isIOS`) | Applies left/right `SafeArea` + side `backgroundColor` strips | Relocates to side strip as [`DuoVerticalBottomNav`](./DuoVerticalBottomNav/SKILL.md) (`bottom: 112pt` to avoid corner punch-hole) | Moves into native UIKit toolbar | Moves into single native UIKit toolbar |
| **Android Foldable / Tablet (Large Screen)** | `width >= 600` (`!Platform.isIOS`) | Wraps page in full-screen `Row` when `BottomNavigationBar` is registered | Converts to full-screen leading `NavigationRail` + `VerticalDivider` | Renders standard Flutter `FloatingActionButton` | Renders standard Flutter widgets in place |
| **Small Screen (Non-Duo)** | `width < 600` (or `< 890` on non-Duo iOS) | Standard Flutter rendering | Renders standard Flutter `BottomNavigationBar` | Renders standard Flutter `FloatingActionButton` | Renders standard Flutter widgets in place |

---

## Widget & Controller Skills Index

Read the specific `SKILL.md` for each widget or controller when implementing or modifying foldable UI:

- **[`DuoSafeArea`](./DuoSafeArea/SKILL.md)**: Root `MaterialApp` wrapper that manages iPhone Duo side safe areas, native UIKit toolbar synchronization, route wrapping (`DuoSafeArea.route`), and large-screen `NavigationRail` hosting.
- **[`DuoTabBar`](./DuoTabBar/SKILL.md)**: Wrapper for `BottomNavigationBar` (relocates to `DuoVerticalBottomNav` on iPhone Duo or converts to `NavigationRail` on >=600px non-Duo screens) and `FloatingActionButton` (integrates into iPhone Duo native toolbar).
- **[`ToolBar`](./ToolBar/SKILL.md)**: Wrapper for `AppBar.actions` (`IconButton`, `BackButton`, etc.) that publishes controls to the iPhone Duo native UIKit toolbar and groups multiple actions into a native pull-down `UIMenu`.
- **[`AppBarBackButtonWidget`](./AppBarBackButtonWidget/SKILL.md)**: Explicit `AppBar.leading` back button that moves to the native UIKit toolbar on iPhone Duo and falls back to a standard `IconButton` on other platforms.
- **[`DuoVerticalBottomNav`](./DuoVerticalBottomNav/SKILL.md)**: Pill-shaped vertical navigation bar rendered inside the iPhone Duo side safe-area strip when a `BottomNavigationBar` is hosted by `DuoTabBar`.
- **[`DeviceWidth`](./DeviceWidth/SKILL.md)**: Controller and `RowItem` helper for responsive 1-pane / 2-pane split layouts (`5:5` or `3:7` based on `isLimited` and hinge angle `> 175°`) and automatic detail-route popping on unfold (`popOnBigScreen`).
- **[`DeviceAngle`](./DeviceAngle/SKILL.md)**: Stream provider for real-time foldable hinge angles (`foldable_devices_ui/angle` `EventChannel`) with immediate replay of the latest angle to newly mounted `StreamBuilder`s.

---

## Complete Minimal App Pattern

```dart
import 'package:flutter/material.dart';
import 'package:foldable_devices_ui/foldable_devices_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DuoSafeArea(
      exception: const [NonSafeAreaScreen],
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: MaterialApp(
        title: 'Foldable App',
        home: const FoldableDeviceScreen(),
      ),
    );
  }
}

class FoldableDeviceScreen extends StatelessWidget {
  const FoldableDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DeviceWidth deviceWidth = DeviceWidth();
    return deviceWidth.updateScreen(
      context,
      isLimited: true,
      rowWidgetItem: RowItem(
        leftWidget: MyHomePage(
          isBigScreen: deviceWidth.isBigScreen(context),
          width: deviceWidth.getWidth(context),
        ),
        rightWidget: NextScreen(
          width: deviceWidth.getWidth(context),
          isBigScreen: deviceWidth.isBigScreen(context),
        ),
      ),
    );
  }
}
```
