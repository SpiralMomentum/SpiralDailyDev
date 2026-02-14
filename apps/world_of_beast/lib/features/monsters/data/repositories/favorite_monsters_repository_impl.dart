import 'package:app_logging/app_logging.dart';
import 'package:utils/result/failure.dart';
import 'package:utils/result/result.dart';

import '../../domain/repositories/favorite_monsters_repository.dart';
import '../datasources/favorite_monsters_local_data_source.dart';

class FavoriteMonstersRepositoryImpl implements FavoriteMonstersRepository {
  FavoriteMonstersRepositoryImpl({
    required FavoriteMonstersLocalDataSource dataSource,
  }) : _dataSource = dataSource;

  final FavoriteMonstersLocalDataSource _dataSource;

  final _logger = AppLogger(tag: 'FavoriteMonstersRepository');

  @override
  Future<Result<Set<String>>> loadFavoriteIds() {
    return guardAsync(
      action: () => _dataSource.loadFavoriteIds(),
      onError: (error, stackTrace) {
        _logger.error(
          '즐겨찾기 목록 로드 실패',
          error: error,
          stackTrace: stackTrace,
        );
        return LocalStorageFailure(
          message: 'Failed to load favorite ids: $error',
          cause: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  @override
  Future<Result<void>> saveFavoriteIds(Set<String> ids) {
    return guardAsync(
      action: () => _dataSource.saveFavoriteIds(ids),
      onError: (error, stackTrace) {
        _logger.error(
          '즐겨찾기 목록 저장 실패 (count: ${ids.length})',
          error: error,
          stackTrace: stackTrace,
        );
        return LocalStorageFailure(
          message: 'Failed to save favorite ids: $error',
          cause: error,
          stackTrace: stackTrace,
        );
      },
    );
  }
}
