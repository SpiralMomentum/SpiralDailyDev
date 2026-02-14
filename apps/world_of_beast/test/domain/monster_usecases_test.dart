import 'package:flutter_test/flutter_test.dart';
import 'package:utils/result/result.dart';
import 'package:world_of_beast/features/monsters/domain/entities/monster.dart';
import 'package:world_of_beast/features/monsters/domain/repositories/monster_repository.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/filter_monsters_by_country_use_case.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/get_monsters_use_case.dart';
import 'package:world_of_beast/features/monsters/domain/usecases/sort_monsters_use_case.dart';

class _FakeMonsterRepository implements MonsterRepository {
  _FakeMonsterRepository(this.monsters);

  final List<Monster> monsters;

  @override
  Future<Result<List<Monster>>> fetchMonsters() async {
    return Success(monsters);
  }
}

void main() {
  const sampleMonsters = [
    Monster(
      id: 'kr-gumiho',
      name: 'Gumiho',
      shortDescription: 'Nine-tailed fox.',
      country: 'KR',
    ),
    Monster(
      id: 'kr-dokkaebi',
      name: 'Dokkaebi',
      shortDescription: 'Playful goblin.',
      country: 'KR',
    ),
    Monster(
      id: 'jp-kappa',
      name: 'Kappa',
      shortDescription: 'River spirit.',
      country: 'JP',
    ),
  ];

  group('SortMonstersUseCase', () {
    test('sorts monsters alphabetically by name', () {
      const useCase = SortMonstersUseCase();
      final sorted = useCase(sampleMonsters);
      expect(sorted.map((m) => m.name), ['Dokkaebi', 'Gumiho', 'Kappa']);
    });
  });

  group('FilterMonstersByCountryUseCase', () {
    const sortUseCase = SortMonstersUseCase();
    const filterUseCase = FilterMonstersByCountryUseCase(
      sortMonsters: sortUseCase,
    );

    test('filters by matching code', () {
      final result = filterUseCase(sampleMonsters, 'KR');
      expect(result, hasLength(2));
      expect(result.every((monster) => monster.country == 'KR'), isTrue);
    });

    test('returns empty list if none match', () {
      final result = filterUseCase(sampleMonsters, 'BR');
      expect(result, isEmpty);
    });
  });

  group('GetMonstersUseCase', () {
    const sortUseCase = SortMonstersUseCase();

    test('fetches monsters and returns them sorted', () async {
      final repository = _FakeMonsterRepository(sampleMonsters);
      final useCase = GetMonstersUseCase(
        repository: repository,
        sortMonsters: sortUseCase,
      );
      final result = await useCase();
      expect(result.isSuccess, isTrue);
      final monsters = (result as Success<List<Monster>>).data;
      expect(monsters.map((m) => m.name), ['Dokkaebi', 'Gumiho', 'Kappa']);
    });
  });
}
