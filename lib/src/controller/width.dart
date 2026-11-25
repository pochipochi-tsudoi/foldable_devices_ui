import 'package:flutter/widgets.dart';
import 'package:foldable_devices_ui/foldable_devices_ui.dart';
import 'package:foldable_devices_ui/src/state/width_state.dart';

/// Manages responsive 1-pane and 2-pane layouts based on screen width and
/// foldable hinge angle.
class DeviceWidth {
  /// Creates a [DeviceWidth] layout controller.
  DeviceWidth() : _state = DeviceWidthState();

  final DeviceWidthState _state;
  late final Stream<double> _angleStream = DeviceAngle().getAngle();

  /// The underlying large-screen state notifier.
  DeviceWidthState get state => _state;

  /// Builds a 1-pane layout on compact screens or a 2-pane [Row] layout on
  /// large/unfolded screens.
  ///
  /// When [isLimited] is `true`, the 2-pane split switches between `3:7` and
  /// `5:5` based on the hinge angle threshold (`175` degrees). When
  /// [popOnBigScreen] is `true`, any pushed detail route is automatically
  /// popped upon expanding to a large screen.
  Widget updateScreen(
    BuildContext context, {
    required RowItem rowWidgetItem,

    /// Controls hinge-angle-based split ratio switching (`3:7` vs `5:5`).
    bool isLimited = false,

    /// Whether to pop the top route when transitioning to a large screen.
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

  /// Returns the current logical width from [MediaQuery].
  double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Updates [state] from [MediaQuery] and returns whether the screen meets
  /// the large-screen breakpoint (`>= 890` on iOS, `>= 600` on other platforms).
  bool isBigScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    _state.updateScreen(width);
    return _state.state;
  }
}

/// Pair of widgets rendered by [DeviceWidth.updateScreen].
class RowItem {
  /// Primary widget shown on compact screens and in the left pane on large
  /// screens.
  final Widget leftWidget;

  /// Secondary widget shown in the right pane on large screens.
  final Widget rightWidget;

  /// Creates a [RowItem] with [leftWidget] and [rightWidget].
  RowItem({required this.leftWidget, required this.rightWidget});
}
