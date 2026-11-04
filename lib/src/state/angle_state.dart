import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AngleState extends ChangeNotifier {
  AngleState._();

  static final AngleState _instance = AngleState._();
  factory AngleState() => _instance;

  static const EventChannel _channel = EventChannel(
    'foldable_devices_ui/angle',
  );

  final StreamController<double> _controller =
      StreamController<double>.broadcast();
  StreamSubscription<dynamic>? _platformSubscription;
  Stream<double>? _angleStream;
  double? _latestAngle;

  Stream<double> getAngle() {
    if (_angleStream == null || _platformSubscription == null) {
      _ensurePlatformSubscription();
      _angleStream = _createAngleStream();
    }
    return _angleStream!;
  }

  void _ensurePlatformSubscription() {
    if (_platformSubscription != null) return;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _platformSubscription = _channel.receiveBroadcastStream().listen(
        (dynamic event) {
          final double value = (event as num).toDouble();
          _latestAngle = value;
          _controller.add(value);
        },
        onError: (Object error, StackTrace stackTrace) {
          _controller.addError(error, stackTrace);
        },
      );
    } else {
      _latestAngle = 0.0;
    }
  }

  Stream<double> _createAngleStream() {
    return Stream<double>.multi((MultiStreamController<double> multi) {
      _ensurePlatformSubscription();
      if (_latestAngle != null) {
        multi.add(_latestAngle!);
      } else if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        multi.add(0.0);
      }
      final StreamSubscription<double> sub = _controller.stream.listen(
        multi.add,
        onError: multi.addError,
        onDone: multi.close,
      );
      multi.onCancel = sub.cancel;
    }, isBroadcast: true);
  }
}
