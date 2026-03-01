import 'package:flutter/material.dart';

import 'package:adage_spark/app/di/service_locator.dart';
import 'package:adage_spark/features/adage/presentation/adage_controller.dart';
import 'package:adage_spark/features/adage/presentation/adage_home_page.dart';
import 'package:adage_spark/features/adage/presentation/adage_theme.dart';

class AdageSparkApp extends StatelessWidget {
  const AdageSparkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getIt<AdageController>()..load();

    return MaterialApp(
      title: 'Adage Spark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AdageColors.backgroundBottom,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AdageColors.accentPrimary,
          brightness: Brightness.dark,
        ),
        textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(
          bodyColor: AdageColors.textPrimary,
          displayColor: AdageColors.textPrimary,
        ),
        useMaterial3: true,
      ),
      home: AdageHomePage(controller: controller),
    );
  }
}
