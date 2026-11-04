---
name: foldable-ui-device-width
description: >-
  Usage and implementation guide for DeviceWidth and RowItem in
  foldable_devices_ui. Use when building responsive 1-pane / 2-pane split
  layouts for foldable devices, checking large-screen breakpoints, or adjusting
  pane ratios (5:5 vs 3:7) by hinge angle.
---

# DeviceWidth & RowItem

Source: [`lib/src/controller/width.dart`](../../../../lib/src/controller/width.dart), [`lib/src/state/width_state.dart`](../../../../lib/src/state/width_state.dart)

`DeviceWidth` manages responsive 1-pane / 2-pane layouts for foldable devices and tablets based on screen width and hinge angle.

---

## Breakpoints (`DeviceWidthState`)

Large screen (`isBigScreen == true`) is determined by `DeviceWidthState.updateScreen(width)`:
- **iOS (`Platform.isIOS`)**: `width >= 890`
- **Android & Other Platforms (`!Platform.isIOS`)**: `width >= 600`

---

## API Reference

### `DeviceWidth`

```dart
class DeviceWidth {
  DeviceWidth();

  DeviceWidthState get state;

  Widget updateScreen(
    BuildContext context, {
    required RowItem rowWidgetItem,
    bool isLimited = false,
    bool popOnBigScreen = true,
  });

  double getWidth(BuildContext context);
  bool isBigScreen(BuildContext context);
}
```

- **`updateScreen(...)`**:
  - **Small screen (`!isBigScreen`)**: Returns `rowWidgetItem.leftWidget` as a single pane.
  - **Large screen (`isBigScreen`)**:
    - If `popOnBigScreen == true` and `Navigator.of(context).canPop()` is true, schedules `navigator.pop()` in a post-frame callback so any detail route pushed while on the small screen is popped when unfolding to the 2-pane view.
    - If `isLimited == true` and hinge `angle > 175`: Returns a `3:7` split `Row` (`Expanded(flex: 3, child: leftWidget)` and `Expanded(flex: 7, child: rightWidget)`).
    - Otherwise: Returns a `5:5` split `Row` (`Expanded(child: leftWidget)` and `Expanded(child: rightWidget)`).
- **`isBigScreen(BuildContext context)`**: Updates `_state` with `MediaQuery.of(context).size.width` and returns whether the screen is large.
- **`getWidth(BuildContext context)`**: Returns `MediaQuery.of(context).size.width`.

### `RowItem`

```dart
class RowItem {
  final Widget leftWidget;
  final Widget rightWidget;

  RowItem({required this.leftWidget, required this.rightWidget});
}
```

---

## Usage Example

```dart
class FoldableDeviceScreen extends StatelessWidget {
  const FoldableDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DeviceWidth deviceWidth = DeviceWidth();
    return deviceWidth.updateScreen(
      isLimited: true,
      context,
      rowWidgetItem: RowItem(
        leftWidget: MyHomePage(
          title: 'Flutter Demo Home Page',
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
