import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'presentation/world_map/world_map_screen.dart';

class WorldFieldGuideApp extends StatelessWidget {
  const WorldFieldGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'World Field Guide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const WorldMapScreen(),
    );
  }
}
