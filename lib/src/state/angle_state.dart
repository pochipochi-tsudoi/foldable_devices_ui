import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AngleState extends ChangeNotifier {
  AngleState._();

  static final AngleState _instance = AngleState._();
  factory AngleState() => _instance;

  Stream<double>? _angleStream;

  Stream<double> getAngle() {
    _angleStream ??= _createAngleStream();
    return _angleStream!;
  }

  Stream<double> _createAngleStream() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      return EventChannel('foldable_devices_ui/angle')
          .receiveBroadcastStream()
          .map((event) => (event as num).toDouble());
    }
    // Android/iOS以外やWebの場合は 0.0 を流し続ける
    return Stream<double>.value(0.0).asBroadcastStream();
  }
}
