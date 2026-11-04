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
  int _tabIndex = 0;

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
          ToolBar(
            child: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Full bleed demo',
                onPressed: () {
                  Navigator.push(
                    context,
                    DuoSafeArea.route(
                      builder: (context) => const NonSafeAreaScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          if (!widget.isBigScreen)
            ToolBar(
              child: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Information',
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
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: DuoTabBar(
        useIndependence: true,
        child: FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
      bottomNavigationBar: DuoTabBar(
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (index) => setState(() => _tabIndex = index),
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
