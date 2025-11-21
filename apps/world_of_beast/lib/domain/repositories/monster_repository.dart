import '../entities/monster.dart';

abstract class MonsterRepository {
  Future<List<Monster>> fetchMonsters();
}
