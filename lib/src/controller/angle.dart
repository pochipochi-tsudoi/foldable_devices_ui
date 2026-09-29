import 'package:foldable_devices_ui/src/state/angle_state.dart';

class DeviceAngle {
  DeviceAngle();

  Stream<double> getAngle() {
    return AngleState().getAngle();
  }
}
