import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:world_of_beast/features/monsters/data/datasources/monsters_local_data_source.dart';

/// A fake AssetBundle that returns the provided JSON string.
class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._json);

  final String _json;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return _json;
  }

  @override
  Future<ByteData> load(String key) async {
    throw UnimplementedError();
  }
}

void main() {
  group('MonstersLocalDataSource', () {
    test('parses JSON correctly and creates Monster objects', () async {
      const json = '''
      [
        {
          "country": "KR",
          "creatures": [
            {"name": "Gumiho", "description": "Nine-tailed fox."},
            {"name": "Dokkaebi", "description": "Playful goblin."}
          ]
        },
        {
          "country": "JP",
          "creatures": [
            {"name": "Kappa", "description": "River spirit."}
          ]
        }
      ]
      ''';
      final dataSource = MonstersLocalDataSource(
        assetBundle: _FakeAssetBundle(json),
      );

      final monsters = await dataSource.loadMonsters();

      expect(monsters, hasLength(3));
      expect(monsters[0].id, 'KR_0');
      expect(monsters[0].name, 'Gumiho');
      expect(monsters[0].shortDescription, 'Nine-tailed fox.');
      expect(monsters[0].country, 'KR');

      expect(monsters[1].id, 'KR_1');
      expect(monsters[1].name, 'Dokkaebi');

      expect(monsters[2].id, 'JP_0');
      expect(monsters[2].name, 'Kappa');
      expect(monsters[2].country, 'JP');
    });

    test('normalizes country code to uppercase', () async {
      const json = '''
      [
        {
          "country": "  br  ",
          "creatures": [
            {"name": "Curupira", "description": "Forest guardian."}
          ]
        }
      ]
      ''';
      final dataSource = MonstersLocalDataSource(
        assetBundle: _FakeAssetBundle(json),
      );

      final monsters = await dataSource.loadMonsters();

      expect(monsters, hasLength(1));
      expect(monsters[0].country, 'BR');
      expect(monsters[0].id, 'BR_0');
    });

    test('skips creatures with empty name', () async {
      const json = '''
      [
        {
          "country": "US",
          "creatures": [
            {"name": "", "description": "No name creature."},
            {"name": "Bigfoot", "description": "Large hairy ape-like creature."},
            {"name": "   ", "description": "Whitespace only name."}
          ]
        }
      ]
      ''';
      final dataSource = MonstersLocalDataSource(
        assetBundle: _FakeAssetBundle(json),
      );

      final monsters = await dataSource.loadMonsters();

      expect(monsters, hasLength(1));
      expect(monsters[0].name, 'Bigfoot');
      // index in the original list is 1 (second creature), so id keeps original indexing
      expect(monsters[0].id, 'US_1');
    });

    test('returns unmodifiable list', () async {
      const json = '''
      [
        {
          "country": "FR",
          "creatures": [
            {"name": "Tarasque", "description": "Dragon-like beast."}
          ]
        }
      ]
      ''';
      final dataSource = MonstersLocalDataSource(
        assetBundle: _FakeAssetBundle(json),
      );

      final monsters = await dataSource.loadMonsters();

      expect(() => monsters.add(monsters[0]), throwsUnsupportedError);
    });
  });
}
