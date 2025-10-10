import 'package:flutter/material.dart';

import 'app/map_switcher_dependencies.dart';

class MapSwitcherApp extends StatefulWidget {
  const MapSwitcherApp({super.key});

  @override
  State<MapSwitcherApp> createState() => _MapSwitcherAppState();
}

class _MapSwitcherAppState extends State<MapSwitcherApp> {
  MapSwitcherDependencies? _dependencies;

  @override
  void initState() {
    super.initState();
    _loadDependencies();
  }

  Future<void> _loadDependencies() async {
    final dependencies = await MapSwitcherDependencies.bootstrap();
    if (!mounted) return;
    setState(() => _dependencies = dependencies);
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = _dependencies;

    if (dependencies == null) {
      return MaterialApp(
        title: 'Map Switcher',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Map Switcher',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: dependencies.router,
    );
  }
}
