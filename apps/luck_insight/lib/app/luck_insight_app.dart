import 'package:flutter/material.dart';

import 'package:luck_insight/features/fortune/presentation/fortune_preview_page.dart';
import 'package:luck_insight/features/fortune/presentation/luck_theme.dart';

class LuckInsightApp extends StatelessWidget {
  const LuckInsightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luck Insight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: LuckColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: LuckColors.accent,
          brightness: Brightness.light,
        ),
        textTheme: ThemeData(brightness: Brightness.light).textTheme.apply(
          bodyColor: LuckColors.textPrimary,
          displayColor: LuckColors.textPrimary,
        ),
        useMaterial3: true,
      ),
      home: const FortunePreviewPage(),
    );
  }
}
