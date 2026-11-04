---
name: foldable-ui-duo-safe-area
description: >-
  Usage and implementation guide for DuoSafeArea and DuoSafeArea.route in
  foldable_devices_ui. Use when wrapping MaterialApp, configuring full-bleed
  exception screens, setting side safe-area background colors, or pushing routes
  imperatively with Navigator.push.
---

# DuoSafeArea

Source: [`lib/src/widgets/duo_safe_area.dart`](../../../../lib/src/widgets/duo_safe_area.dart)

`DuoSafeArea` is the top-level widget that wraps a Navigator-based `MaterialApp`. It provides:
1. **iPhone Duo Side Safe-Area Management**: Applies left and right `SafeArea` insets (`SafeArea(left: true, top: false, right: true, bottom: false)`) and paints `backgroundColor` behind the left/right system toolbar strips.
2. **iPhone Duo Native Toolbar Sync**: Collects actions registered by [`ToolBar`](../ToolBar/SKILL.md), [`AppBarBackButtonWidget`](../AppBarBackButtonWidget/SKILL.md), and [`DuoTabBar`](../DuoTabBar/SKILL.md) via `AppActionScope` and sends them to the native iOS UIKit toolbar (`MethodChannel('foldable_devices_ui/device')`).
3. **Vertical Bottom Navigation & NavigationRail Hosting**:
   - On **iPhone Duo** (both unfolded and folded sub-display): Renders `BottomNavigationBar` registered via [`DuoTabBar`](../DuoTabBar/SKILL.md) as [`DuoVerticalBottomNav`](../DuoVerticalBottomNav/SKILL.md) inside the side safe-area strip. Dynamically adapts `bottomInset` based on the Dynamic Island / camera punch-hole orientation (`bottom: 112.0` when rotated 180° so the cutout sits at the bottom, `bottom: 16.0` when the cutout sits at the top or in portrait so it avoids colliding with the top UIKit toolbar).
   - On **non-iPhone Duo large screens** (`DeviceWidthState.state == true`, i.e., `width >= 600` on Android/other platforms): Renders `BottomNavigationBar` registered via [`DuoTabBar`](../DuoTabBar/SKILL.md) as a full-screen standard Flutter `NavigationRail` + `VerticalDivider(thickness: 1, width: 1)` at the leading edge of the route.

---

## Constructor & Parameters

```dart
const DuoSafeArea({
  Key? key,
  List<Type> exception = const <Type>[],
  Color? backgroundColor,
  required Widget child, // Must be a Navigator-based MaterialApp
})
```

- **`child`** (`Widget`, required): Must be a `MaterialApp` (asserted at runtime). `MaterialApp.router` (`routerConfig` / `routerDelegate`) is not supported and throws a `FlutterError`.
- **`exception`** (`List<Type>`, default `const <Type>[]`): Exact widget `runtimeType`s that should bypass automatic side `SafeArea` and `NavigationRail` wrapping (for example, full-bleed camera or preview screens). Note that `AppActionScope` is still provided to exception pages so [`AppBarBackButtonWidget`](../AppBarBackButtonWidget/SKILL.md) and [`ToolBar`](../ToolBar/SKILL.md) continue to work on iPhone Duo.
- **`backgroundColor`** (`Color?`): Color painted behind the left and right safe-area inset strips on iPhone Duo. Always set this (e.g. `Theme.of(context).colorScheme.surface`), otherwise the side inset region defaults to black/transparent.

---

## Imperative Navigation with `DuoSafeArea.route`

Routes pushed directly with `MaterialPageRoute` bypass `MaterialApp`'s route builders. When pushing routes imperatively with `Navigator.push`, always use `DuoSafeArea.route`:

```dart
Navigator.push(
  context,
  DuoSafeArea.route(
    builder: (context) => const NonSafeAreaScreen(),
  ),
);
```

`DuoSafeArea.route<T>` accepts the same parameters as `MaterialPageRoute<T>` (`builder`, `settings`, `maintainState`, `fullscreenDialog`, `requestFocus`, `allowSnapshotting`, `barrierDismissible`, `traversalEdgeBehavior`, `directionalTraversalEdgeBehavior`) and automatically wraps the built page in `DuoSafeArea`'s scope while respecting `exception`.

---

## Usage Example

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DuoSafeArea(
      exception: const [NonSafeAreaScreen],
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const FoldableDeviceScreen(),
      ),
    );
  }
}
```
