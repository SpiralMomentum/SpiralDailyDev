import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/life_table/data/asset_life_table_repository.dart';
import 'package:life_balance/features/life_table/data/life_table_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late JsonLifeTable table;

  setUpAll(() async {
    final result = await AssetLifeTableRepository().load();
    table = result.dataOrNull!;
  });

  test('11 countries including KR', () {
    expect(table.countryCodes.length, 11);
    expect(table.countryCodes, contains('KR'));
    expect(table.countryCodes.toSet(), {
      'KR',
      'US',
      'CN',
      'DE',
      'JP',
      'GB',
      'IN',
      'FR',
      'RU',
      'IT',
      'BR',
    });
  });

  test('every country has 101 positive values per sex', () {
    for (final code in table.countryCodes) {
      for (final sex in Sex.values) {
        for (var age = 0; age <= 100; age++) {
          final v = table.remainingYears(countryCode: code, sex: sex, age: age);
          expect(v, greaterThan(0), reason: '$code $sex $age');
        }
      }
    }
  });

  test('raw asset arrays have exactly 101 entries', () async {
    final raw = await rootBundle.loadString(AssetLifeTableRepository.assetPath);
    final countries =
        (jsonDecode(raw) as Map<String, dynamic>)['countries']
            as Map<String, dynamic>;
    for (final entry in countries.entries) {
      final c = entry.value as Map<String, dynamic>;
      expect((c['male'] as List).length, 101, reason: entry.key);
      expect((c['female'] as List).length, 101, reason: entry.key);
    }
  });

  test('KR male age 0 matches KOSIS 2024 (80.8)', () {
    expect(
      table.remainingYears(countryCode: 'KR', sex: Sex.male, age: 0),
      80.8,
    );
  });

  test('sources carry names and years', () {
    final kr = table.countries.firstWhere((c) => c.code == 'KR');
    expect(kr.name, '대한민국');
    expect(kr.sourceYear, 2024);
    final others = table.countries.where((c) => c.code != 'KR');
    expect(others.map((c) => c.sourceYear).toSet(), {2023});
  });
}
