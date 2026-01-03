import 'package:flutter/material.dart';

import 'package:world_field_guide/app/theme/app_theme.dart';
import 'package:world_field_guide/features/world_map/data/repositories/world_local_specialty_repository_impl.dart';
import 'package:world_field_guide/features/world_map/data/repositories/world_map_repository_impl.dart';
import 'package:world_field_guide/features/world_map/domain/usecases/get_country_specialties_use_case.dart';
import 'package:world_field_guide/features/world_map/domain/usecases/get_world_map_use_case.dart';
import 'package:world_field_guide/features/world_map/presentation/world_map_screen.dart';

class WorldFieldGuideApp extends StatelessWidget {
  const WorldFieldGuideApp({
    super.key,
    this.themeVariant = AppThemeVariant.light,
  });

  final AppThemeVariant themeVariant;

  @override
  Widget build(BuildContext context) {
    final ThemeData effectiveTheme = themeVariant == AppThemeVariant.dark
        ? AppTheme.light
        : AppTheme.resolve(themeVariant);

    final getWorldMapUseCase = GetWorldMapUseCase(
      repository: const WorldMapRepositoryImpl(),
    );
    final getCountrySpecialtiesUseCase = GetCountrySpecialtiesUseCase(
      repository: const WorldLocalSpecialtyRepositoryImpl(),
    );

    return MaterialApp(
      title: 'World Field Guide',
      debugShowCheckedModeBanner: false,
      theme: effectiveTheme,
      darkTheme: AppTheme.dark,
      themeMode: AppTheme.modeFor(themeVariant),
      home: WorldMapScreen(
        themeVariant: themeVariant,
        getWorldMapUseCase: getWorldMapUseCase,
        getCountrySpecialtiesUseCase: getCountrySpecialtiesUseCase,
      ),
    );
  }
}
