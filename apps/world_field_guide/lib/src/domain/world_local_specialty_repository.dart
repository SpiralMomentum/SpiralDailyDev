import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class WorldLocalSpecialtyRepository {
  const WorldLocalSpecialtyRepository({
    this.assetPath = 'lib/src/data/world_local_specialty.json',
  });

  final String assetPath;

  static Map<String, List<String>>? _cache;

  Future<List<String>> fetchForCountry(String countryCode) async {
    final specialties = await _loadSpecialties();
    final key = countryCode.toLowerCase();
    final values = specialties[key];
    if (values == null) {
      return const [];
    }
    return List<String>.unmodifiable(values);
  }

  Future<Map<String, List<String>>> _loadSpecialties() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }

    final raw = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;
    final parsed = decoded.map((key, value) {
      final entries = List<String>.unmodifiable(
        (value as List<dynamic>).map((item) => item.toString()),
      );
      return MapEntry(key.toLowerCase(), entries);
    });
    _cache = parsed;
    return parsed;
  }
}
