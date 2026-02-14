import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utils/result/result.dart';

import 'package:world_of_beast/features/monsters/data/datasources/favorite_monsters_local_data_source.dart';
import 'package:world_of_beast/features/monsters/data/repositories/favorite_monsters_repository_impl.dart';

void main() {
  group('FavoriteMonstersRepositoryImpl', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    FavoriteMonstersRepositoryImpl createRepository() {
      return FavoriteMonstersRepositoryImpl(
        dataSource: FavoriteMonstersLocalDataSource(preferences: prefs),
      );
    }

    test('loadFavoriteIds returns Success with empty set when no data stored',
        () async {
      final repository = createRepository();

      final result = await repository.loadFavoriteIds();

      expect(result.isSuccess, isTrue);
      final ids = (result as Success<Set<String>>).data;
      expect(ids, isEmpty);
    });

    test('loadFavoriteIds returns Success with stored ids', () async {
      await prefs.setStringList('favoriteMonsterIds', ['id1', 'id2', 'id3']);
      final repository = createRepository();

      final result = await repository.loadFavoriteIds();

      expect(result.isSuccess, isTrue);
      final ids = (result as Success<Set<String>>).data;
      expect(ids, containsAll(['id1', 'id2', 'id3']));
      expect(ids, hasLength(3));
    });

    test('saveFavoriteIds returns Success after persisting', () async {
      final repository = createRepository();

      final result =
          await repository.saveFavoriteIds({'alpha', 'beta', 'gamma'});

      expect(result.isSuccess, isTrue);
      final stored = prefs.getStringList('favoriteMonsterIds');
      expect(stored, isNotNull);
      expect(stored, containsAll(['alpha', 'beta', 'gamma']));
    });

    test('saveFavoriteIds then loadFavoriteIds round-trips correctly',
        () async {
      final repository = createRepository();
      await repository.saveFavoriteIds({'x', 'y'});

      final result = await repository.loadFavoriteIds();

      expect(result.isSuccess, isTrue);
      final ids = (result as Success<Set<String>>).data;
      expect(ids, containsAll(['x', 'y']));
    });
  });
}
