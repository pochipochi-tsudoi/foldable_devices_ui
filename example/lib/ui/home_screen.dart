import 'package:example/ui/next_screend.dart';
import 'package:example/ui/non_safe_area_screen.dart';
import 'package:flutter/material.dart';
import 'package:foldable_devices_ui/foldable_devices_ui.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.isBigScreen,
    required this.width,
  });

  final String title;
  final bool isBigScreen;
  final double width;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                DuoSafeArea.route(builder: (context) => NonSafeAreaScreen()),
              );
            },
          ),
          widget.isBigScreen
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      DuoSafeArea.route(
                        builder: (context) => NextScreen(
                          width: widget.width,
                          isBigScreen: widget.isBigScreen,
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  DuoSafeArea.route(builder: (_) => const NonSafeAreaScreen()),
                );
              },
              child: const Text('Open full-bleed exception screen'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
