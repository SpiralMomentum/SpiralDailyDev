import 'package:countries_world_map/countries_world_map.dart';
import 'package:flutter/material.dart';
import 'package:world_map_widget/world_map_widget.dart';

import 'package:world_field_guide/app/theme/app_theme.dart';
import 'package:world_field_guide/core/analytics/analytics_events.dart';
import 'package:app_analytics/app_analytics.dart';
import 'package:world_field_guide/features/world_map/domain/entities/world_map_data.dart';
import 'package:world_field_guide/features/world_map/domain/usecases/get_country_specialties_use_case.dart';
import 'package:world_field_guide/features/world_map/domain/usecases/get_world_map_use_case.dart';
import 'package:world_field_guide/features/world_map/presentation/country_map_screen.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({
    super.key,
    required this.themeVariant,
    required this.getWorldMapUseCase,
    required this.getCountrySpecialtiesUseCase,
    this.analyticsTracker,
  });

  final AppThemeVariant themeVariant;
  final GetWorldMapUseCase getWorldMapUseCase;
  final GetCountrySpecialtiesUseCase getCountrySpecialtiesUseCase;
  final AnalyticsTracker? analyticsTracker;

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  static const Color _darkMapFill = Color(0xFF1F3B57);
  static const Color _accentMapFill = Color(0xFFFFD8CA);

  late final GetWorldMapUseCase _getWorldMapUseCase;
  late final WorldMapData _data;

  void _openCountryDetails(WorldCountryTapDetails details) {
    // 국가 선택 이벤트 트래킹
    widget.analyticsTracker?.trackEvent(
      AnalyticsEvents.countrySelected,
      {
        'country_id': details.countryId,
        if (details.countryName != null) 'country_name': details.countryName!,
      },
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CountryMapScreen(
          instruction: details.instructions,
          countryId: details.countryId,
          countryName: details.countryName,
          getCountrySpecialtiesUseCase: widget.getCountrySpecialtiesUseCase,
          analyticsTracker: widget.analyticsTracker,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _getWorldMapUseCase = widget.getWorldMapUseCase;
    _data = _getWorldMapUseCase().dataOrNull ??
        const WorldMapData(caption: '전 세계 특산품을 불러오는 중입니다.');

    // 세계 지도 화면 조회 이벤트 트래킹
    widget.analyticsTracker?.trackScreenView('WorldMapScreen');
    widget.analyticsTracker?.trackEvent(AnalyticsEvents.worldMapViewed);
  }

  @override
  Widget build(BuildContext context) {
    final captionColor = _captionColorForTheme();
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Semantics(
                label: '세계 지도 - 국가를 탭하여 특산품을 확인하세요',
                child: WorldMapWidget(
                caption: _data.caption,
                canvasColor: _mapCanvasColorForTheme(),
                countryBorder: _borderForTheme(),
                mapColor: _mapColorForTheme(),
                captionTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: captionColor,
                      height: 1.4,
                    ) ??
                    TextStyle(
                      color: captionColor,
                      height: 1.4,
                    ),
                onCountryTap: _openCountryDetails,
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Color _mapCanvasColorForTheme() {
    switch (widget.themeVariant) {
      case AppThemeVariant.dark:
        return AppTheme.midnightSurface;
      case AppThemeVariant.accent:
        return Colors.white;
      case AppThemeVariant.light:
        return AppTheme.mapCanvas;
    }
  }

  Color _mapColorForTheme() {
    switch (widget.themeVariant) {
      case AppThemeVariant.dark:
        return _darkMapFill;
      case AppThemeVariant.accent:
        return _accentMapFill;
      case AppThemeVariant.light:
        return const Color(0xFFFAE4C2);
    }
  }

  CountryBorder _borderForTheme() {
    switch (widget.themeVariant) {
      case AppThemeVariant.dark:
        return const CountryBorder(
          color: Colors.white,
          width: 0.4,
        );
      case AppThemeVariant.accent:
        return const CountryBorder(
          color: AppTheme.accentSecondary,
          width: 0.4,
        );
      case AppThemeVariant.light:
        return const CountryBorder(
          color: AppTheme.deepNavy,
          width: 0.4,
        );
    }
  }

  Color _captionColorForTheme() {
    switch (widget.themeVariant) {
      case AppThemeVariant.dark:
        return Colors.white;
      case AppThemeVariant.accent:
        return AppTheme.accentSecondary;
      case AppThemeVariant.light:
        return AppTheme.deepNavy;
    }
  }
}
