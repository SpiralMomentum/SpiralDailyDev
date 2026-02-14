import 'package:flutter_test/flutter_test.dart';
import 'package:utils/result/result.dart';

import 'package:world_of_beast/features/monsters/data/datasources/monsters_local_data_source.dart';
import 'package:world_of_beast/features/monsters/data/repositories/monster_repository_impl.dart';
import 'package:world_of_beast/features/monsters/domain/entities/monster.dart';

import 'package:flutter/services.dart';

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

/// A fake AssetBundle that throws on loadString.
class _ThrowingAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    throw Exception('File not found');
  }

  @override
  Future<ByteData> load(String key) async {
    throw UnimplementedError();
  }
}

void main() {
  group('MonsterRepositoryImpl', () {
    test('returns Success with parsed monsters from JSON', () async {
      const json = '''
      [
        {
          "country": "kr",
          "creatures": [
            {"name": "Gumiho", "description": "Nine-tailed fox."},
            {"name": "Dokkaebi", "description": "Playful goblin."}
          ]
        }
      ]
      ''';
      final dataSource = MonstersLocalDataSource(
        assetBundle: _FakeAssetBundle(json),
      );
      final repository = MonsterRepositoryImpl(dataSource: dataSource);

      final result = await repository.fetchMonsters();

      expect(result.isSuccess, isTrue);
      final monsters = (result as Success<List<Monster>>).data;
      expect(monsters, hasLength(2));
      expect(monsters[0].name, 'Gumiho');
      expect(monsters[0].country, 'KR');
      expect(monsters[1].name, 'Dokkaebi');
    });

    test('returns ErrorResult when JSON parsing fails', () async {
      final dataSource = MonstersLocalDataSource(
        assetBundle: _ThrowingAssetBundle(),
      );
      final repository = MonsterRepositoryImpl(dataSource: dataSource);

      final result = await repository.fetchMonsters();

      expect(result.isError, isTrue);
      expect(result.failureOrNull, isNotNull);
      expect(
        result.failureOrNull!.message,
        contains('Failed to load monsters'),
      );
    });

    test('returns Success with initialData when provided', () async {
      const monsters = [
        Monster(
          id: 'test_0',
          name: 'Test',
          shortDescription: 'desc',
          country: 'US',
        ),
      ];
      final dataSource = MonstersLocalDataSource(
        assetBundle: _ThrowingAssetBundle(),
      );
      final repository = MonsterRepositoryImpl(
        dataSource: dataSource,
        initialData: monsters,
      );

      final result = await repository.fetchMonsters();

      expect(result.isSuccess, isTrue);
      final data = (result as Success<List<Monster>>).data;
      expect(data, hasLength(1));
      expect(data[0].name, 'Test');
    });

    test('normalizes country codes to uppercase', () async {
      const json = '''
      [
        {
          "country": "jp",
          "creatures": [
            {"name": "Kappa", "description": "River spirit."}
          ]
        }
      ]
      ''';
      final dataSource = MonstersLocalDataSource(
        assetBundle: _FakeAssetBundle(json),
      );
      final repository = MonsterRepositoryImpl(dataSource: dataSource);

      final result = await repository.fetchMonsters();

      expect(result.isSuccess, isTrue);
      final monsters = (result as Success<List<Monster>>).data;
      expect(monsters[0].country, 'JP');
    });
  });
}
