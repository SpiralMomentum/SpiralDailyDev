import 'package:app_logging/app_logging.dart';
import 'package:utils/result/failure.dart';
import 'package:utils/result/result.dart';

import '../../domain/entities/monster.dart';
import '../../domain/repositories/monster_repository.dart';
import '../datasources/monsters_local_data_source.dart';

class MonsterRepositoryImpl implements MonsterRepository {
  MonsterRepositoryImpl({
    required MonstersLocalDataSource dataSource,
    List<Monster>? initialData,
  }) : _dataSource = dataSource,
       _initialData = initialData;

  final MonstersLocalDataSource _dataSource;
  final List<Monster>? _initialData;

  final _logger = AppLogger(tag: 'MonsterRepository');

  @override
  Future<Result<List<Monster>>> fetchMonsters() async {
    final initial = _initialData;
    if (initial != null) {
      return Success(List<Monster>.unmodifiable(initial));
    }
    return guardAsync(
      action: () => _dataSource.loadMonsters(),
      onError: (error, stackTrace) {
        _logger.error(
          '몬스터 목록 로드 실패',
          error: error,
          stackTrace: stackTrace,
        );
        return ParsingFailure(
          message: 'Failed to load monsters: $error',
          cause: error,
          stackTrace: stackTrace,
        );
      },
    );
  }
}
