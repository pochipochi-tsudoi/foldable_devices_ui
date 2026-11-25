## 0.1.0

* Initial release of `foldable_devices_ui`.
* Added `DuoSafeArea` for automatic side safe-area management, full-bleed route exceptions, native iPhone Duo UIKit toolbar synchronization, and support for both Navigator-based `MaterialApp` and `MaterialApp.router` (`material_ui` and `flutter/material.dart`).
* Added `DuoTabBar` and `DuoVerticalBottomNav` to relocate `BottomNavigationBar` into a vertical side strip on iPhone Duo or a leading `NavigationRail` on Android foldable/tablet large screens, and integrate `FloatingActionButton` into the iPhone Duo native toolbar.
* Added `ToolBar` and `AppBarBackButtonWidget` to host supported Flutter controls in the iPhone Duo native toolbar with icon rasterization and automatic HIG `UIMenu` grouping for multiple actions.
* Added `DeviceWidth`, `RowItem`, and `DeviceAngle` for responsive 1-pane / 2-pane layouts and real-time hinge-angle streaming on Android and iOS.
