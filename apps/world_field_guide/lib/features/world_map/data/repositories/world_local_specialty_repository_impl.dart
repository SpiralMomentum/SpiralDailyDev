import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:utils/utils.dart';
import 'package:world_field_guide/features/world_map/domain/repositories/world_local_specialty_repository.dart';

class WorldLocalSpecialtyRepositoryImpl
    implements WorldLocalSpecialtyRepository {
  const WorldLocalSpecialtyRepositoryImpl({
    this.assetPath = 'lib/features/world_map/data/world_local_specialty.json',
  });

  final String assetPath;

  static Map<String, List<String>>? _cache;

  @override
  Future<Result<List<String>>> fetchForCountry(String countryCode) async {
    return guardAsync(
      action: () async {
        final specialties = await _loadSpecialties();
        final key = countryCode.toLowerCase();
        final values = specialties[key];
        if (values == null) {
          return const [];
        }
        return List<String>.unmodifiable(values);
      },
      onError: (error, stackTrace) => ParsingFailure(
        message: '특산품 정보를 불러오지 못했습니다.',
        cause: error,
        stackTrace: stackTrace,
      ),
    );
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
