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

## Device detection

The iOS plugin identifies iPhone Duo using its hardware machine identifier (`iPhone19,4`) and exposes the result internally to Dart. Hinge angle and open/closed posture are not used for device detection. The model identifier mapping is based on [AppleDB's device list](https://appledb.dev/device-selection/iPhone.html), not an Apple model-identification API. Unknown identifiers and unsupported platforms return `false`.

SafeArea uses Flutter's per-edge `MediaQuery` padding; the package doesn't hardcode inset dimensions. See Apple's [iPhone Duo HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo) and [Safe Area guidance](https://developer.apple.com/videos/play/tech-talks/111461/).
