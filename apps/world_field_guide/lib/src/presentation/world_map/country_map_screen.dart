import 'package:flutter/material.dart';

import 'package:countries_world_map/countries_world_map.dart';

import '../../theme/app_theme.dart';

class CountryMapScreen extends StatelessWidget {
  const CountryMapScreen({super.key, required this.instruction});

  final String instruction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 12,
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(160),
                child: SimpleMap(
                  instructions: instruction,
                  fit: BoxFit.contain,
                  defaultColor: const Color(0xFFFAE4C2),
                  countryBorder: const CountryBorder(
                    color: AppTheme.deepNavy,
                    width: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
