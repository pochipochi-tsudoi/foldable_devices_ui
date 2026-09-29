import 'package:example/ui/home_screen.dart';
import 'package:example/ui/next_screend.dart';
import 'package:example/ui/non_safe_area_screen.dart';
import 'package:flutter/material.dart';
import 'package:foldable_devices_ui/foldable_devices_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DuoSafeArea(
      exception: const [NonSafeAreaScreen],

      ///Note: Failing to set this property will result in a black background.
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
        home: const FoldableDeviceScreen(),
      ),
    );
  }
}

/// [isLimited] is Optional. If set to true, the layout will be 5:5 when the hinge angle reaches 180 degrees, and 3:7 when the angle is below 180 degrees.
class FoldableDeviceScreen extends StatelessWidget {
  const FoldableDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DeviceWidth deviceWidth = DeviceWidth();
    return deviceWidth.updateScreen(
      isLimited: true,
      context,
      rowWidgetItem: RowItem(
        leftWidget: MyHomePage(
          title: 'Flutter Demo Home Page',
          isBigScreen: deviceWidth.isBigScreen(context),
          width: deviceWidth.getWidth(context),
        ),
        rightWidget: NextScreen(
          width: deviceWidth.getWidth(context),
          isBigScreen: deviceWidth.isBigScreen(context),
        ),
      ),
    );
  }
}
