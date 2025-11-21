import 'package:flutter/material.dart';

import 'presentation/world_map/world_map_screen.dart';
import 'theme/app_theme.dart';

class WorldFieldGuideApp extends StatelessWidget {
  const WorldFieldGuideApp({
    super.key,
    this.themeVariant = AppThemeVariant.light,
  });

  final AppThemeVariant themeVariant;

  @override
  Widget build(BuildContext context) {
    final ThemeData effectiveTheme =
        themeVariant == AppThemeVariant.dark ? AppTheme.light : AppTheme.resolve(themeVariant);

    return MaterialApp(
      title: 'World Field Guide',
      debugShowCheckedModeBanner: false,
      theme: effectiveTheme,
      darkTheme: AppTheme.dark,
      themeMode: AppTheme.modeFor(themeVariant),
      home: WorldMapScreen(themeVariant: themeVariant),
    );
  }
}
