import 'dart:convert';

import 'package:app_logging/app_logging.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/monster.dart';

class MonstersLocalDataSource {
  MonstersLocalDataSource({
    this.assetBundle,
    this.assetPath = 'lib/data/monsters.json',
  });

  final AssetBundle? assetBundle;
  final String assetPath;

  final _logger = AppLogger(tag: 'MonstersLocalDataSource');

  Future<List<Monster>> loadMonsters() async {
    final bundle = assetBundle ?? rootBundle;

    late final String raw;
    try {
      raw = await bundle.loadString(assetPath);
    } catch (error, stackTrace) {
      _logger.error(
        'JSON 파일 로드 실패: $assetPath',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }

    late final List<dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as List<dynamic>;
    } catch (error, stackTrace) {
      _logger.error(
        'JSON 파싱 실패: $assetPath',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }

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
