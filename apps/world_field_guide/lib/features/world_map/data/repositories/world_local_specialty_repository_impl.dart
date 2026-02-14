import 'dart:convert';

import 'package:app_logging/app_logging.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:utils/utils.dart';
import 'package:world_field_guide/features/world_map/domain/repositories/world_local_specialty_repository.dart';

final _logger = AppLogger(tag: 'SpecialtyRepository');

class WorldLocalSpecialtyRepositoryImpl
    implements WorldLocalSpecialtyRepository {
  const WorldLocalSpecialtyRepositoryImpl({
    this.assetPath = 'lib/features/world_map/data/world_local_specialty.json',
  });

  final String assetPath;

  static Map<String, List<String>>? _cache;

  /// 테스트 전용: 정적 캐시를 초기화한다.
  @visibleForTesting
  static void resetCache() => _cache = null;

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
      onError: (error, stackTrace) {
        _logger.error(
          '특산품 JSON 파싱 실패',
          error: error,
          stackTrace: stackTrace,
        );
        return ParsingFailure(
          message: '특산품 정보를 불러오지 못했습니다.',
          cause: error,
          stackTrace: stackTrace,
        );
      },
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
