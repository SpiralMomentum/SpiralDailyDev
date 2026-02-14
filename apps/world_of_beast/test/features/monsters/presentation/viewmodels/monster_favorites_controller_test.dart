import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/failure.dart';
import 'package:utils/result/result.dart';

import 'package:world_of_beast/features/monsters/domain/entities/monster.dart';
import 'package:world_of_beast/features/monsters/domain/repositories/favorite_monsters_repository.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/load_favorite_monster_ids_use_case.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/save_favorite_monster_ids_use_case.dart';
import 'package:world_of_beast/features/monsters/presentation/viewmodels/monster_favorites_controller.dart';

class MockFavoriteMonstersRepository extends Mock
    implements FavoriteMonstersRepository {}

void main() {
  late MockFavoriteMonstersRepository mockRepository;
  late MonsterFavoritesController controller;

  setUp(() {
    mockRepository = MockFavoriteMonstersRepository();
    controller = MonsterFavoritesController(
      loadFavorites: LoadFavoriteMonsterIdsUseCase(repository: mockRepository),
      saveFavorites: SaveFavoriteMonsterIdsUseCase(repository: mockRepository),
    );
  });

  setUpAll(() {
    registerFallbackValue(<String>{});
  });

  tearDown(() {
    controller.dispose();
  });

  group('MonsterFavoritesController', () {
    test('initial state: not ready, empty favorites', () {
      expect(controller.isReady, isFalse);
      expect(controller.favoriteIds, isEmpty);
    });

    test('initialize loads favorite ids on success', () async {
      when(() => mockRepository.loadFavoriteIds())
          .thenAnswer((_) async => const Success({'id1', 'id2'}));

      await controller.initialize();

      expect(controller.isReady, isTrue);
      expect(controller.favoriteIds, containsAll(['id1', 'id2']));
    });

    test('initialize sets empty favorites on error', () async {
      when(() => mockRepository.loadFavoriteIds()).thenAnswer(
        (_) async =>
            const ErrorResult(LocalStorageFailure(message: 'read error')),
      );

      await controller.initialize();

      expect(controller.isReady, isTrue);
      expect(controller.favoriteIds, isEmpty);
    });

    test('initialize only runs once', () async {
      when(() => mockRepository.loadFavoriteIds())
          .thenAnswer((_) async => const Success({'id1'}));

      await controller.initialize();
      await controller.initialize();

      verify(() => mockRepository.loadFavoriteIds()).called(1);
    });

    test('toggleFavorite adds and removes correctly', () async {
      when(() => mockRepository.loadFavoriteIds())
          .thenAnswer((_) async => const Success(<String>{}));
      when(() => mockRepository.saveFavoriteIds(any()))
          .thenAnswer((_) async => const Success(null));
      await controller.initialize();

      // Add
      final addResult = await controller.toggleFavorite('monster_a');
      expect(addResult, isTrue);
      expect(controller.isFavorite('monster_a'), isTrue);

      // Remove
      final removeResult = await controller.toggleFavorite('monster_a');
      expect(removeResult, isFalse);
      expect(controller.isFavorite('monster_a'), isFalse);
    });

    test('toggleFavorite persists to repository', () async {
      when(() => mockRepository.loadFavoriteIds())
          .thenAnswer((_) async => const Success(<String>{}));
      when(() => mockRepository.saveFavoriteIds(any()))
          .thenAnswer((_) async => const Success(null));
      await controller.initialize();

      await controller.toggleFavorite('test_id');

      verify(() => mockRepository.saveFavoriteIds(any())).called(1);
    });

    test('filterFavorites returns only favorited monsters sorted by name',
        () async {
      when(() => mockRepository.loadFavoriteIds())
          .thenAnswer((_) async => const Success({'m2', 'm3'}));
      when(() => mockRepository.saveFavoriteIds(any()))
          .thenAnswer((_) async => const Success(null));
      await controller.initialize();

      const monsters = [
        Monster(
          id: 'm1',
          name: 'Zephyr',
          shortDescription: 'desc',
          country: 'US',
        ),
        Monster(
          id: 'm2',
          name: 'Banshee',
          shortDescription: 'desc',
          country: 'IE',
        ),
        Monster(
          id: 'm3',
          name: 'Alpha',
          shortDescription: 'desc',
          country: 'GR',
        ),
      ];

      final filtered = controller.filterFavorites(monsters);

      expect(filtered, hasLength(2));
      expect(filtered[0].name, 'Alpha');
      expect(filtered[1].name, 'Banshee');
    });

    test('filterFavorites returns empty when no favorites', () async {
      when(() => mockRepository.loadFavoriteIds())
          .thenAnswer((_) async => const Success(<String>{}));
      await controller.initialize();

      const monsters = [
        Monster(
          id: 'm1',
          name: 'Dragon',
          shortDescription: 'desc',
          country: 'CN',
        ),
      ];

      final filtered = controller.filterFavorites(monsters);
      expect(filtered, isEmpty);
    });

    test('notifies listeners on state changes', () async {
      when(() => mockRepository.loadFavoriteIds())
          .thenAnswer((_) async => const Success(<String>{}));
      when(() => mockRepository.saveFavoriteIds(any()))
          .thenAnswer((_) async => const Success(null));

      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.initialize();
      expect(notifyCount, 1); // initialize notifies once

      await controller.toggleFavorite('id1');
      expect(notifyCount, 2); // toggle notifies
    });
  });
}
