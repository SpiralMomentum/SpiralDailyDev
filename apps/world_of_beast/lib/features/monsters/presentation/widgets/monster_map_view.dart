import 'package:flutter/material.dart';
import 'package:world_map_widget/world_map_widget.dart';

/// 세계 지도에서 몬스터 서식 국가를 표시하는 맵 뷰 위젯.
class MonsterMapView extends StatelessWidget {
  const MonsterMapView({
    super.key,
    required this.caption,
    required this.activeCountries,
    required this.activeCountryColor,
    required this.inactiveCountryColor,
    this.onCountrySelected,
  });

  final String caption;
  final Set<String> activeCountries;
  final Color activeCountryColor;
  final Color inactiveCountryColor;
  final CountryTapCallback? onCountrySelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: WorldMapWidget(
              key: const ValueKey('worldMapWidget'),
              caption: caption,
              mapColor: inactiveCountryColor,
              countryColors: _buildCountryColors(),
              onCountryTap: onCountrySelected == null
                  ? null
                  : (details) => _handleCountryTap(details),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color>? _buildCountryColors() {
    if (activeCountries.isEmpty) {
      return null;
    }
    return {
      for (final code in activeCountries)
        code.toLowerCase(): activeCountryColor,
    };
  }

  void _handleCountryTap(WorldCountryTapDetails details) {
    final normalized = details.countryId.toUpperCase();
    if (!activeCountries.contains(normalized)) {
      return;
    }
    onCountrySelected?.call(details);
  }
}
