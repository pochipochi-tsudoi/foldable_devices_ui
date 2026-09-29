import 'package:flutter/services.dart';

class DuoDeviceInfo {
  DuoDeviceInfo._();

  static const MethodChannel _channel = MethodChannel(
    'foldable_devices_ui/device',
  );

  static Future<bool> get isIphoneDuo async {
    try {
      return await _channel.invokeMethod<bool>('isIphoneDuo') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
