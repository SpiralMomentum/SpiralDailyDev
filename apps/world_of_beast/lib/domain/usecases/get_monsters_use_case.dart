import '../entities/monster.dart';
import '../repositories/monster_repository.dart';
import 'sort_monsters_use_case.dart';

class GetMonstersUseCase {
  const GetMonstersUseCase({
    required MonsterRepository repository,
    required SortMonstersUseCase sortMonsters,
  }) : _repository = repository,
       _sortMonsters = sortMonsters;

  final MonsterRepository _repository;
  final SortMonstersUseCase _sortMonsters;

  Future<List<Monster>> call() async {
    final monsters = await _repository.fetchMonsters();
    return _sortMonsters(monsters);
  }
}
