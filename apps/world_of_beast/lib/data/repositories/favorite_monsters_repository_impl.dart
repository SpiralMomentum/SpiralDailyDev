import '../../domain/repositories/favorite_monsters_repository.dart';
import '../datasources/favorite_monsters_local_data_source.dart';

class FavoriteMonstersRepositoryImpl implements FavoriteMonstersRepository {
  const FavoriteMonstersRepositoryImpl({
    required FavoriteMonstersLocalDataSource dataSource,
  }) : _dataSource = dataSource;

  final FavoriteMonstersLocalDataSource _dataSource;

  @override
  Future<Set<String>> loadFavoriteIds() {
    return _dataSource.loadFavoriteIds();
  }

  @override
  Future<void> saveFavoriteIds(Set<String> ids) {
    return _dataSource.saveFavoriteIds(ids);
  }
}
