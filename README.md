# foldable_devices_ui

Adaptive Flutter UI widgets and controllers for foldable devices across iOS (iPhone Duo) and Android (foldables and large-screen tablets).

## Features

- **`DuoSafeArea`**: Wraps `MaterialApp` or `MaterialApp.router` (both `package:material_ui/material_ui.dart` and `package:flutter/material.dart`) to manage iPhone Duo left/right safe-area insets, side strip background colors, full-bleed route exceptions, native UIKit toolbar synchronization, and large-screen `NavigationRail` hosting.
- **`DuoTabBar` & `DuoVerticalBottomNav`**: Adapts `BottomNavigationBar` into a vertical side navigation bar on iPhone Duo or a leading `NavigationRail` on Android foldable/tablet large screens (`width >= 600`), and integrates `FloatingActionButton` into the native iPhone Duo toolbar.
- **`ToolBar` & `AppBarBackButtonWidget`**: Publishes supported Flutter controls to the native UIKit toolbar on iPhone Duo—rasterizing Flutter `Icon` glyphs directly and automatically grouping multiple actions into a native pull-down `UIMenu`—while preserving standard Flutter widgets on other platforms.
- **`DeviceWidth` & `RowItem`**: Responsive 1-pane / 2-pane split layouts that adapt to screen width and hinge angle, with automatic detail-route popping when unfolding.
- **`DeviceAngle`**: Broadcast `Stream<double>` of real-time foldable hinge angles (`0.0`–`180.0`) with immediate replay of the latest angle to newly mounted listeners.

## Platform Behavior Overview

| Platform / State | Large-Screen Threshold | `DuoSafeArea` | `DuoTabBar` (`BottomNavigationBar`) | `DuoTabBar` (`FloatingActionButton`) | `ToolBar` & `AppBarBackButtonWidget` |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **iPhone Duo (Unfolded)** | `width >= 890` (iOS) | Left/right `SafeArea` + side `backgroundColor` strips | Relocates to side strip as `DuoVerticalBottomNav` | Moves into native UIKit toolbar | Moves into native UIKit toolbar (2+ actions grouped into `UIMenu`) |
| **iPhone Duo (Folded / Sub-display)** | `width < 890` (iOS) | Left/right `SafeArea` + side `backgroundColor` strips | Relocates to side strip as `DuoVerticalBottomNav` | Moves into native UIKit toolbar | Moves into native UIKit toolbar |
| **Android Foldable / Tablet** | `width >= 600` (non-iOS) | Hosts leading `NavigationRail` + `VerticalDivider` | Converts to leading `NavigationRail` | Standard Flutter `FloatingActionButton` | Standard Flutter widgets in place |
| **Standard Phone** | `< 600` (Android) / `< 890` (iOS) | Standard Flutter rendering | Standard Flutter `BottomNavigationBar` | Standard Flutter `FloatingActionButton` | Standard Flutter widgets in place |

## Installation

Add `foldable_devices_ui` to your `pubspec.yaml`:

```bash
flutter pub add foldable_devices_ui
```

Then import the package:

```dart
import 'package:foldable_devices_ui/foldable_devices_ui.dart';
```

## Usage

### `DuoSafeArea`

Wrap your `MaterialApp` (Navigator-based or `MaterialApp.router`, such as with `go_router`) once at the root of your app:

```dart
import 'package:foldable_devices_ui/foldable_devices_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    DuoSafeArea(
      exception: const [CameraScreen, FullBleedScreen],
      backgroundColor: Colors.black,
      child: MaterialApp(
        home: const HomeScreen(),
        routes: {
          '/settings': (_) => const SettingsScreen(),
        },
      ),
    ),
  );
}
```

- `exception` is optional and defaults to an empty list. Entries match the exact runtime type of pages returned from `home`, `routes`, `onGenerateRoute`, `onUnknownRoute`, or `DuoSafeArea.route`.
- `backgroundColor` is optional. When provided, it paints only the left and right safe-area strips on iPhone Duo without changing the page's own background or top/bottom edges.

For imperative pushes with `Navigator.push`, create the route with `DuoSafeArea.route` so the page type can be checked against `exception`:

```dart
Navigator.push(
  context,
  DuoSafeArea.route(
    builder: (_) => const DetailsScreen(),
  ),
);
```

### `ToolBar`, `AppBarBackButtonWidget`, and `DuoTabBar`

Wrap AppBar actions with `ToolBar`, AppBar leading back buttons with `AppBarBackButtonWidget`, and `BottomNavigationBar` / `FloatingActionButton` with `DuoTabBar`:

```dart
Scaffold(
  appBar: AppBar(
    automaticallyImplyLeading: false,
    leading: const AppBarBackButtonWidget(),
    title: const Text('Home'),
    actions: [
      ToolBar(
        child: [
          IconButton(
            tooltip: 'Search',
            onPressed: onSearch,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
    ],
  ),
  body: const Center(child: Text('Content')),
  floatingActionButton: DuoTabBar(
    useIndependence: true,
    child: FloatingActionButton(
      tooltip: 'Add',
      onPressed: onAdd,
      child: const Icon(Icons.add),
    ),
  ),
  bottomNavigationBar: DuoTabBar(
    child: BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onSelectTab,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    ),
  ),
)
```

- Supported `ToolBar` children: `IconButton`, `BackButton`, `FloatingActionButton`, `BottomNavigationBar`, and `NavigationBar`. Unsupported custom widgets remain Flutter-rendered.
- Flutter `Icon` glyphs are rasterized from their `IconData` and theme for native display rather than guessed as SF Symbols.
- When 2 or more secondary actions are active on a route on iPhone Duo, they are automatically grouped into a single native `UIMenu` button.
- Set `automaticallyImplyLeading: false` when using `AppBarBackButtonWidget` to avoid showing Flutter's implicit back button alongside the native back item.

### `DeviceWidth` & `RowItem`

Use `DeviceWidth` to switch between a 1-pane layout on compact screens and a 2-pane split layout on unfolded/large screens:

```dart
class ResponsiveScreen extends StatelessWidget {
  const ResponsiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceWidth = DeviceWidth();
    return deviceWidth.updateScreen(
      context,
      isLimited: true,
      rowWidgetItem: RowItem(
        leftWidget: MasterPane(isBigScreen: deviceWidth.isBigScreen(context)),
        rightWidget: DetailPane(width: deviceWidth.getWidth(context)),
      ),
    );
  }
}
```

### `DeviceAngle`

Subscribe to real-time hinge-angle updates (`0.0` to `180.0` degrees):

```dart
StreamBuilder<double>(
  stream: DeviceAngle().getAngle(),
  builder: (context, snapshot) {
    final angle = snapshot.data ?? 0.0;
    return Text('Hinge angle: ${angle.toStringAsFixed(1)}°');
  },
)
```

## Device Detection

The iOS plugin identifies iPhone Duo using its hardware machine identifier (`iPhone19,4`) and exposes the result internally to Dart. Hinge angle and open/closed posture are not used for device identification. The model identifier mapping is based on [AppleDB's device list](https://appledb.dev/device-selection/iPhone.html), not an Apple model-identification API. Unknown identifiers and unsupported platforms return `false`.

SafeArea relies on Flutter's per-edge `MediaQuery` padding without hardcoding inset dimensions. See Apple's [iPhone Duo HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo) and [Safe Area guidance](https://developer.apple.com/videos/play/tech-talks/111461/).

## License

This package is released under the [MIT License](LICENSE).
