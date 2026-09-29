import 'dart:io';

import 'package:flutter/foundation.dart';

class DeviceWidthState extends ChangeNotifier {
  DeviceWidthState([bool state = false]) : _state = state;

  bool _state;

  bool get state => _state;

  void updateScreen(double width) {
    final newState = Platform.isIOS ? width >= 890 : width >= 600;
    if (_state == newState) return;
    _state = newState;
    notifyListeners();
  }
}
