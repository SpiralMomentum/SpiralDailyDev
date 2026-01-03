import '../repositories/favorite_monsters_repository.dart';

class SaveFavoriteMonsterIdsUseCase {
  const SaveFavoriteMonsterIdsUseCase({
    required FavoriteMonstersRepository repository,
  }) : _repository = repository;

  final FavoriteMonstersRepository _repository;

  Future<void> call(Set<String> ids) {
    return _repository.saveFavoriteIds(ids);
  }
}
