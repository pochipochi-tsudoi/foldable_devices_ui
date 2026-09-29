/*
Complete usage example (place the wrapper around MaterialApp once):

import 'package:flutter/material.dart';
import 'package:foldable_devices_ui/foldable_devices_ui.dart';

void main() {
  runApp(
    DuoSafeArea(
      exception: const [NonSafeAreaScreen],
      backgroundColor: Colors.black,
      child: MaterialApp(
        home: const HomeScreen(),
        routes: {
          '/full-bleed': (_) => const NonSafeAreaScreen(),
        },
      ),
    ),
  );
}

// DuoSafeArea adds only left/right insets for the system toolbar area;
// top and bottom padding are intentionally not added.
// backgroundColor paints the left/right inset strips behind regular pages.

// For imperative Navigator.push routes, use the package route factory:
Navigator.push(
  context,
  DuoSafeArea.route(
    builder: (_) => const NonSafeAreaScreen(),
  ),
);
*/

import 'package:flutter/material.dart';

class NonSafeAreaScreen extends StatelessWidget {
  const NonSafeAreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('SafeArea Verification (iPhone Duo: No SafeArea)'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
