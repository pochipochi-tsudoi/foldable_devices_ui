import 'package:flutter/widgets.dart';
import 'package:foldable_devices_ui/foldable_devices_ui.dart';
import 'package:foldable_devices_ui/src/state/width_state.dart';

class DeviceWidth {
  DeviceWidth() : _state = DeviceWidthState();

  final DeviceWidthState _state;
  late final Stream<double> _angleStream = DeviceAngle().getAngle();

  DeviceWidthState get state => _state;

  Widget updateScreen(
    BuildContext context, {
    required RowItem rowWidgetItem,

    /// When `true`, the layout becomes 5:5 once the hinge angle reaches
    /// 175 degrees, and stays 3:7 while the angle is below it.
    bool isLimited = false,

    bool popOnBigScreen = true,
  }) {
    final width = MediaQuery.of(context).size.width;
    _state.updateScreen(width);

    return StreamBuilder<double>(
      stream: _angleStream,
      builder: (context, snapshot) {
        final angle = snapshot.data ?? 0.0;
        final isBigScreen = _state.state;

        if (!isBigScreen) {
          return rowWidgetItem.leftWidget;
        }

        if (popOnBigScreen) {
          _popIfNeeded(context);
        }

        if (isLimited && angle > 175) {
          return Row(
            children: [
              Expanded(flex: 3, child: rowWidgetItem.leftWidget),
              Expanded(flex: 7, child: rowWidgetItem.rightWidget),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: rowWidgetItem.leftWidget),
            Expanded(child: rowWidgetItem.rightWidget),
          ],
        );
      },
    );
  }

  void _popIfNeeded(BuildContext context) {
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.canPop()) {
        navigator.pop();
      }
    });
  }

  double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  bool isBigScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    _state.updateScreen(width);
    return _state.state;
  }
}

class RowItem {
  final Widget leftWidget;
  final Widget rightWidget;

  RowItem({required this.leftWidget, required this.rightWidget});
}
