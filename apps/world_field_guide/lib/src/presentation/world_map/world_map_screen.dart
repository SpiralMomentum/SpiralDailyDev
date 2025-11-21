import 'package:countries_world_map/countries_world_map.dart';
import 'package:flutter/material.dart';
import 'package:world_map_widget/world_map_widget.dart';

import '../../application/world_map_controller.dart';
import '../../domain/world_map_data.dart';
import '../../theme/app_theme.dart';
import 'country_map_screen.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({
    super.key,
    required this.themeVariant,
  });

  final AppThemeVariant themeVariant;

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  static const Color _darkMapFill = Color(0xFF1F3B57);
  static const Color _accentMapFill = Color(0xFFFFD8CA);

  late final WorldMapController _controller;
  late final WorldMapData _data;

  void _openCountryDetails(WorldCountryTapDetails details) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CountryMapScreen(
          instruction: details.instructions,
          countryId: details.countryId,
          countryName: details.countryName,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = WorldMapController();
    _data = _controller.worldMap;
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
      default:
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
      default:
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
      default:
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
      default:
        return AppTheme.deepNavy;
    }
  }
}
