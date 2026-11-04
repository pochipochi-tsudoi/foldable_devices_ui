---
name: foldable-ui-app-bar-back-button-widget
description: >-
  Usage and implementation guide for AppBarBackButtonWidget in
  foldable_devices_ui. Use when adding a back button to AppBar.leading that
  automatically moves into the native iPhone Duo toolbar.
---

# AppBarBackButtonWidget

Source: [`lib/src/widgets/app_action.dart`](../../../../lib/src/widgets/app_action.dart)

`AppBarBackButtonWidget` is a back button designed for `AppBar.leading`. When hosted inside [`DuoSafeArea`](../DuoSafeArea/SKILL.md) on iPhone Duo, it moves into the native UIKit toolbar (`AppActionRole.back`, `priority: 100`). On all other platforms, it renders a standard Flutter `IconButton` in `AppBar.leading`.

---

## Constructor & Parameters

```dart
const AppBarBackButtonWidget({
  Key? key,
  IconData icon = Icons.arrow_back_ios_new,
  Color? color,
  String? tooltip = 'Back',
  VoidCallback? onPressed,
})
```

- **`icon`** (`IconData`, default `Icons.arrow_back_ios_new`): Icon glyph to display and rasterize.
- **`color`** (`Color?`): Optional icon color override.
- **`tooltip`** (`String?`, default `'Back'`): Accessibility label and native menu/toolbar title.
- **`onPressed`** (`VoidCallback?`): Custom callback. When omitted (`null`), defaults to `Navigator.maybePop(context)`.

---

## Required `AppBar` Configuration

Always set `automaticallyImplyLeading: false` on the containing `AppBar` when using `AppBarBackButtonWidget`, or when relying on [`DuoSafeArea`](../DuoSafeArea/SKILL.md)'s automatic native back button on pushed screens, so Flutter does not render a duplicate back button inside the `AppBar`:

```dart
Scaffold(
  appBar: AppBar(
    automaticallyImplyLeading: false,
    leading: const AppBarBackButtonWidget(),
    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    title: const Text('Full Bleed'),
  ),
  body: const Center(
    child: Text('Detail Screen'),
  ),
)
```
