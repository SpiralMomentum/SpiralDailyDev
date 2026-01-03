import 'package:flutter/material.dart';

import 'package:adage_spark/features/adage/data/datasources/adage_local_data_source.dart';
import 'package:adage_spark/features/adage/data/repositories/adage_repository_impl.dart';
import 'package:adage_spark/features/adage/domain/usecases/add_adage_quote_use_case.dart';
import 'package:adage_spark/features/adage/domain/usecases/get_adage_quotes_use_case.dart';
import 'package:adage_spark/features/adage/presentation/adage_controller.dart';
import 'package:adage_spark/features/adage/presentation/adage_home_page.dart';
import 'package:adage_spark/features/adage/presentation/adage_theme.dart';

class AdageSparkApp extends StatefulWidget {
  const AdageSparkApp({super.key});

  @override
  State<AdageSparkApp> createState() => _AdageSparkAppState();
}

class _AdageSparkAppState extends State<AdageSparkApp> {
  late final AdageController _controller;

  @override
  void initState() {
    super.initState();
    final dataSource = AdageLocalDataSource();
    final repository = AdageRepositoryImpl(localDataSource: dataSource);
    _controller = AdageController(
      getAdageQuotesUseCase: GetAdageQuotesUseCase(repository: repository),
      addAdageQuoteUseCase: AddAdageQuoteUseCase(repository: repository),
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      home: AdageHomePage(controller: _controller),
    );
  }
}
