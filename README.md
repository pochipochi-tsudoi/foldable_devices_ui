# foldable_devices_ui

Flutter helpers for foldable-device layouts, including automatic iPhone Duo SafeArea handling.

## DuoSafeArea

Wrap a Navigator-based `MaterialApp` once. On iPhone Duo, recognized pages receive only the current left/right safe-area padding, except the widget types listed in `exception`. Top and bottom insets are left untouched so the wrapper doesn't add padding for existing top/bottom system navigation areas. Other devices keep their existing rendering. The OS continues to render its own toolbar and status items; the side padding keeps Flutter content clear of that area.

```dart
import 'package:flutter/material.dart';
import 'package:foldable_devices_ui/foldable_devices_ui.dart';

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

`exception` is optional and defaults to an empty list. Match entries against the exact runtime type of the page widget returned from `home`, `routes`, `onGenerateRoute`, or `onUnknownRoute`.

`backgroundColor` is optional. When provided, it paints only the left and right safe-area strips on iPhone Duo; it doesn't change the page's own background and doesn't paint the top or bottom edges.

## iPhone Duo native toolbar actions

Wrap the supported controls with `ToolBar(child: [...])`. On iPhone Duo they move into the UIKit navigation toolbar; on other platforms they stay in their original Flutter layout slots.

```dart
Scaffold(
  appBar: AppBar(
    automaticallyImplyLeading: false,
    leading: const AppBarBackButtonWidget(),
    actions: [
      ToolBar(child: [
        IconButton(
          tooltip: 'Search',
          onPressed: search,
          icon: const Icon(Icons.search),
        ),
      ]),
    ],
  ),
  floatingActionButton: ToolBar(child: [
    FloatingActionButton(
      tooltip: 'Add',
      onPressed: addItem,
      child: const Icon(Icons.add),
    ),
  ]),
  bottomNavigationBar: ToolBar(child: [bottomNavigationBar]),
)
```

Supported controls are `IconButton`, `BackButton`, `FloatingActionButton`, `BottomNavigationBar`, and `NavigationBar`. Action priority is inferred from the control role: Back/Close first, primary actions next, followed by regular actions and navigation destinations. Flutter `Icon` glyphs are rasterized with their `IconData` and icon theme for native display; they aren't guessed or substituted with an SF Symbol. Unsupported custom widgets remain Flutter-rendered.

Navigator push/pop updates the native back item. Use `AppBarBackButtonWidget` for an explicit AppBar back control and set `automaticallyImplyLeading: false` to avoid also showing Flutter's implicit back button.

For imperative pushes, create the route with `DuoSafeArea.route` so the page type can be checked:

```dart
Navigator.push(
  context,
  DuoSafeArea.route(
    builder: (_) => const DetailsScreen(),
  ),
);
```

Routes created directly with `MaterialPageRoute` bypass MaterialApp's route builders and aren't automatically wrapped. `MaterialApp.router` and custom `Route` implementations aren't currently supported by the wrapper.

## iPhone Duo native toolbar actions

Place supported controls in `ToolBar(child: [...])`. On iPhone Duo these controls are sent to the UIKit navigation bar; on other platforms the original Flutter widgets are returned in their original slots.

```dart
Scaffold(
  appBar: AppBar(
    automaticallyImplyLeading: false,
    leading: const AppBarBackButtonWidget(),
    actions: [
      ToolBar(child: [
        IconButton(
          tooltip: 'Search',
          onPressed: search,
          icon: const Icon(Icons.search),
        ),
      ]),
    ],
  ),
  floatingActionButton: ToolBar(child: [
    FloatingActionButton(
      tooltip: 'Add',
      onPressed: addItem,
      child: const Icon(Icons.add),
    ),
  ]),
  bottomNavigationBar: ToolBar(child: [bottomNavigationBar]),
)
```

Supported children are `IconButton`, `BackButton`, `FloatingActionButton`, `BottomNavigationBar`, and `NavigationBar`. Priority is inferred by role: back/close first, primary actions next, and standard or destination actions after them. `Icon` widgets are rasterized from their `IconData` and theme so native items keep the same glyph instead of being guessed as an SF Symbol. Unsupported custom widgets remain Flutter-rendered.

Use `AppBarBackButtonWidget` as `AppBar.leading` with `automaticallyImplyLeading: false` to avoid showing both the native back item and Flutter's implicit AppBar back button. Navigator push/pop updates the native back item and tapping it pops the active Flutter route.

## iPhone Duo native toolbar actions

Wrap supported controls with `ToolBar(child: [...])`. On iPhone Duo the controls move to the UIKit navigation bar; on other platforms the original Flutter widgets are rendered in their original slots.

```dart
Scaffold(
  appBar: AppBar(
    automaticallyImplyLeading: false,
    leading: const AppBarBackButtonWidget(),
    actions: [
      ToolBar(child: [
        IconButton(
          tooltip: 'Search',
          onPressed: search,
          icon: const Icon(Icons.search),
        ),
      ]),
    ],
  ),
  floatingActionButton: ToolBar(child: [
    FloatingActionButton(
      tooltip: 'Add',
      onPressed: addItem,
      child: const Icon(Icons.add),
    ),
  ]),
  bottomNavigationBar: ToolBar(child: [bottomNavigationBar]),
)
```

Supported children are `IconButton`, `BackButton`, `FloatingActionButton`, `BottomNavigationBar`, and `NavigationBar`. Priority is inferred from the widget role: Back/Close first, primary actions next, and other actions or navigation destinations after them. `Icon` glyphs are rasterized from their Flutter `IconData` and theme, rather than guessed as SF Symbols. Unsupported widgets remain Flutter-rendered.

Use `AppBarBackButtonWidget` with `automaticallyImplyLeading: false` to avoid duplicating Flutter's implicit back button. Navigator push/pop updates the native back item, whose action pops the active Flutter navigator.

## Device detection

The iOS plugin identifies iPhone Duo using its hardware machine identifier (`iPhone19,4`) and exposes the result internally to Dart. Hinge angle and open/closed posture are not used for device detection. The model identifier mapping is based on [AppleDB's device list](https://appledb.dev/device-selection/iPhone.html), not an Apple model-identification API. Unknown identifiers and unsupported platforms return `false`.

SafeArea uses Flutter's per-edge `MediaQuery` padding; the package doesn't hardcode inset dimensions. See Apple's [iPhone Duo HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo) and [Safe Area guidance](https://developer.apple.com/videos/play/tech-talks/111461/).
