import 'dart:io';

import 'package:flutter/foundation.dart';

/// Tracks whether the current viewport width meets the large-screen threshold.
class DeviceWidthState extends ChangeNotifier {
  /// Creates a [DeviceWidthState] with an optional initial [state].
  DeviceWidthState([bool state = false]) : _state = state;

  bool _state;

  /// Whether the screen currently qualifies as a large screen.
  bool get state => _state;

  /// Updates [state] from the given logical screen [width]
  /// (`>= 890` on iOS, `>= 600` on other platforms).
  void updateScreen(double width) {
    final newState = Platform.isIOS ? width >= 890 : width >= 600;
    if (_state == newState) return;
    _state = newState;
    notifyListeners();
  }
}
