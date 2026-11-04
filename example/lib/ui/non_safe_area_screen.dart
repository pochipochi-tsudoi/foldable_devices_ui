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

// Move supported Scaffold controls to the iPhone Duo toolbar:
//
// Scaffold(
//   appBar: AppBar(
//     automaticallyImplyLeading: false,
//     leading: const AppBarBackButtonWidget(),
//     actions: [
//       ToolBar(child: [
//         IconButton(
//           tooltip: 'Search',
//           onPressed: search,
//           icon: const Icon(Icons.search),
//         ),
//       ]),
//     ],
//   ),
//   floatingActionButton: ToolBar(child: [
//     FloatingActionButton(
//       tooltip: 'Add',
//       onPressed: addItem,
//       child: const Icon(Icons.add),
//     ),
//   ]),
//   bottomNavigationBar: ToolBar(child: [bottomNavigationBar]),
// )

// For imperative Navigator.push routes, use the package route factory:
Navigator.push(
  context,
  DuoSafeArea.route(
    builder: (_) => const NonSafeAreaScreen(),
  ),
);
*/

import 'package:flutter/material.dart';
import 'package:foldable_devices_ui/foldable_devices_ui.dart';

class NonSafeAreaScreen extends StatelessWidget {
  const NonSafeAreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppBarBackButtonWidget(),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Full Bleed'),
      ),
      body: Column(
        children: [
          const Text('SafeArea Verification (iPhone Duo: No SafeArea)'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
