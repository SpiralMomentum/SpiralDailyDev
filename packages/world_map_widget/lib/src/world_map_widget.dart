import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import 'package:flutter/material.dart';

import 'world_country_tap_details.dart';
import 'world_map_instructions.dart';

class WorldMapWidget extends StatelessWidget {
  const WorldMapWidget({
    super.key,
    required this.caption,
    this.onCountryTap,
    this.canvasColor = const Color(0xFFE3F1FF),
    this.mapColor = const Color(0xFFFAE4C2),
    this.countryColors,
    this.countryBorder = const CountryBorder(
      color: Color(0xFF0B3F6A),
      width: 0.4,
    ),
    this.captionTextStyle,
  });

  final String caption;
  final CountryTapCallback? onCountryTap;
  final Color canvasColor;
  final Color mapColor;
  final Map<String, Color>? countryColors;
  final CountryBorder countryBorder;
  final TextStyle? captionTextStyle;

  void _handleCountryTap(BuildContext context, String id, String? name) {
    if (onCountryTap == null) {
      return;
    }

    final instructions = WorldMapInstructions.resolve(id);
    if (instructions == null) {
      return;
    }

    onCountryTap!(
      WorldCountryTapDetails(
        countryId: id,
        countryName: name,
        instructions: instructions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: canvasColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(25, 11, 63, 106),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 12,
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(160),
                child: SimpleMap(
                  instructions: SMapWorld.instructions,
                  fit: BoxFit.contain,
                  defaultColor: mapColor,
                  colors: countryColors,
                  countryBorder: countryBorder,
                  callback: (selectedCountryId, selectedCountryName, _) {
                    _handleCountryTap(
                      context,
                      selectedCountryId,
                      selectedCountryName,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: captionTextStyle ??
              theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF0B3F6A),
                height: 1.4,
              ) ??
              const TextStyle(
                color: Color(0xFF0B3F6A),
                height: 1.4,
              ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
