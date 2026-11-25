import 'package:foldable_devices_ui/src/state/angle_state.dart';

/// Provides real-time hinge angle updates for foldable devices.
class DeviceAngle {
  /// Creates a [DeviceAngle] controller.
  DeviceAngle();

  /// Returns a broadcast stream of the device's hinge angle in degrees
  /// (`0.0` to `180.0`), immediately replaying the latest known value to new
  /// subscribers.
  Stream<double> getAngle() {
    return AngleState().getAngle();
  }
}
