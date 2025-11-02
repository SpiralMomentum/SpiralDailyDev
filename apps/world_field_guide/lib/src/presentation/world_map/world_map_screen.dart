import 'package:flutter/material.dart';

import '../../application/world_map_controller.dart';
import '../../domain/world_map_data.dart';
import '../../theme/app_theme.dart';
import 'widgets/world_map_view.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  late final WorldMapController _controller;
  late final WorldMapData _data;

  @override
  void initState() {
    super.initState();
    _controller = WorldMapController();
    _data = _controller.worldMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Expanded(child: WorldMapView(data: _data))],
        ),
      ),
    );
  }
}
