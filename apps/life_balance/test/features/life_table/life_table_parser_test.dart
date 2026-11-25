import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/life_table/data/asset_life_table_repository.dart';
import 'package:life_balance/features/life_table/data/life_table_parser.dart';
import 'package:utils/utils.dart';

List<double> _series(double start) =>
    List<double>.generate(101, (i) => start - i * 0.5);

Map<String, dynamic> _country(String name, double m, double f) => {
  'name': name,
  'source': {
    'name': 'WHO',
    'url': 'https://example.com',
    'year': 2021,
    'retrieved': '2026-11-01',
  },
  'male': _series(m),
  'female': _series(f),
};

String _json({Map<String, dynamic>? extra}) => jsonEncode({
  'version': '2026.11',
  'countries': {
    'KR': _country('대한민국', 80, 86),
    'JP': _country('일본', 81, 87),
    ...?extra,
  },
});

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.content);
  final String? content;

  @override
  Future<ByteData> load(String key) async => throw FlutterError('not found');

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (content == null) throw FlutterError('not found');
    return content!;
  }
}

void main() {
  group('parseLifeTable', () {
    test('값을 조회한다', () {
      final table = parseLifeTable(_json()).dataOrNull!;
      expect(
        table.remainingYears(countryCode: 'KR', sex: Sex.male, age: 0),
        80,
      );
      expect(
        table.remainingYears(countryCode: 'JP', sex: Sex.female, age: 10),
        82,
      );
      expect(table.countryCodes, unorderedEquals(['KR', 'JP']));
    });

    test('100 초과 나이는 100세 값을 쓴다', () {
      final table = parseLifeTable(_json()).dataOrNull!;
      expect(
        table.remainingYears(countryCode: 'KR', sex: Sex.male, age: 130),
        30,
      );
    });

    test('알 수 없는 국가는 ArgumentError', () {
      final table = parseLifeTable(_json()).dataOrNull!;
      expect(
        () => table.remainingYears(countryCode: 'ZZ', sex: Sex.male, age: 1),
        throwsArgumentError,
      );
    });

    test('국가 메타데이터를 노출한다', () {
      final c = parseLifeTable(
        _json(),
      ).dataOrNull!.countries.firstWhere((e) => e.code == 'KR');
      expect(c.name, '대한민국');
      expect(c.sourceName, 'WHO');
      expect(c.sourceYear, 2021);
    });

    test('배열 길이 100이면 ParsingFailure', () {
      final bad = _country('X', 80, 86)..['male'] = _series(80).sublist(0, 100);
      final r = parseLifeTable(_json(extra: {'XX': bad}));
      expect(r, isA<ErrorResult<JsonLifeTable>>());
      expect(r.failureOrNull, isA<ParsingFailure>());
    });

    test('깨진 JSON/누락 필드는 ParsingFailure', () {
      expect(parseLifeTable('not json').failureOrNull, isA<ParsingFailure>());
      expect(parseLifeTable('{}').failureOrNull, isA<ParsingFailure>());
    });
  });

  group('AssetLifeTableRepository', () {
    test('번들에서 로드한다', () async {
      final r = await AssetLifeTableRepository(
        bundle: _FakeBundle(_json()),
      ).load();
      expect(r.dataOrNull!.countryCodes.length, 2);
    });

    test('에셋이 없으면 ParsingFailure', () async {
      final r = await AssetLifeTableRepository(
        bundle: _FakeBundle(null),
      ).load();
      expect(r.failureOrNull, isA<ParsingFailure>());
    });
  });
}
