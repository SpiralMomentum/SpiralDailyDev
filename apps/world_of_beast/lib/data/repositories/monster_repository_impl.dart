import '../../domain/entities/monster.dart';
import '../../domain/repositories/monster_repository.dart';
import '../datasources/monsters_local_data_source.dart';

class MonsterRepositoryImpl implements MonsterRepository {
  const MonsterRepositoryImpl({
    required MonstersLocalDataSource dataSource,
    List<Monster>? initialData,
  }) : _dataSource = dataSource,
       _initialData = initialData;

  final MonstersLocalDataSource _dataSource;
  final List<Monster>? _initialData;

  @override
  Future<List<Monster>> fetchMonsters() async {
    final initial = _initialData;
    if (initial != null) {
      return List<Monster>.unmodifiable(initial);
    }
    return _dataSource.loadMonsters();
  }
}
