import 'package:utils/result/result.dart';

import '../entities/monster.dart';

abstract class MonsterRepository {
  Future<Result<List<Monster>>> fetchMonsters();
}
