---
name: foldable-ui-device-angle
description: >-
  Usage and implementation guide for DeviceAngle and AngleState in
  foldable_devices_ui. Use when subscribing to real-time foldable hinge angle
  updates via StreamBuilder.
---

# DeviceAngle

Source: [`lib/src/controller/angle.dart`](../../../../lib/src/controller/angle.dart), [`lib/src/state/angle_state.dart`](../../../../lib/src/state/angle_state.dart)

`DeviceAngle` provides a broadcast `Stream<double>` of the device's hinge angle in degrees (`0.0` to `180.0`).

---

## API Reference

```dart
class DeviceAngle {
  DeviceAngle();

  Stream<double> getAngle();
}
```

---

## Platform & Stream Behavior (`AngleState`)

- **Channel**: Listens to `EventChannel('foldable_devices_ui/angle')`.
  - **Android**: Streams values from `Sensor.TYPE_HINGE_ANGLE` (`FoldableDevicesUiPlugin.kt`). Returns `0.0` if the device has no hinge sensor.
  - **iOS**: Streams `180.0` (unfolded) or `0.0` (folded/sub-display) from `FoldableDevicesUiPlugin.swift`.
  - **Web / Desktop**: Emits `0.0`.
- **Immediate Replay for New Subscribers**:
  `AngleState` caches the latest angle value (`_latestAngle`) from the platform channel and uses `Stream<double>.multi(..., isBroadcast: true)`. When a widget (such as a right-pane detail screen mounted after unfolding) subscribes to `DeviceAngle().getAngle()`, it **immediately receives the latest cached hinge angle** without waiting for the physical hinge to move again.

---

## Usage Example

```dart
StreamBuilder<double>(
  stream: DeviceAngle().getAngle(),
  builder: (context, snapshot) {
    final double angle = snapshot.data ?? 0.0;
    return Text(
      'angle: $angle',
      style: const TextStyle(fontSize: 18),
    );
  },
)
```
