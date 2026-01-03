import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/monster.dart';

class MonstersLocalDataSource {
  const MonstersLocalDataSource({
    this.assetBundle,
    this.assetPath = 'lib/data/monsters.json',
  });

  final AssetBundle? assetBundle;
  final String assetPath;

  Future<List<Monster>> loadMonsters() async {
    final bundle = assetBundle ?? rootBundle;
    final raw = await bundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;

    final monsters = <Monster>[];
    for (final entry in decoded) {
      final countryCode = (entry['country'] as String? ?? '')
          .trim()
          .toUpperCase();
      final creatures = entry['creatures'] as List<dynamic>? ?? const [];

      for (var index = 0; index < creatures.length; index++) {
        final creature = creatures[index] as Map<String, dynamic>;
        final name = (creature['name'] as String? ?? '').trim();
        final description = (creature['description'] as String? ?? '').trim();

        if (name.isEmpty) {
          continue;
        }

        monsters.add(
          Monster(
            id: '${countryCode}_$index',
            name: name,
            shortDescription: description,
            country: countryCode,
          ),
        );
      }
    }

    return List<Monster>.unmodifiable(monsters);
  }
}
