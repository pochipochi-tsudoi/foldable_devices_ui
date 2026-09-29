import 'package:flutter/material.dart';
import 'package:foldable_devices_ui/foldable_devices_ui.dart';

class NextScreen extends StatelessWidget {
  final double width;
  final bool isBigScreen;
  const NextScreen({super.key, required this.width, required this.isBigScreen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Information'),
      ),
      body: Column(
        mainAxisAlignment: .center,
        crossAxisAlignment: .center,
        children: [
          Text('isBigScreen:$isBigScreen', style: TextStyle(fontSize: 24)),
          SizedBox(height: 20),
          Text('getWidth: $width', style: TextStyle(fontSize: 24)),
          SizedBox(height: 20),

          /// StreamBuilder widget is used to listen to the angle stream and display the current angle value.
          StreamBuilder<double>(
            stream: DeviceAngle().getAngle(),
            builder: (context, snapshot) {
              return Text(
                'angle: ${snapshot.data ?? 0.0}',
                style: TextStyle(fontSize: 18),
              );
            },
          ),
        ],
      ),
    );
  }
}
