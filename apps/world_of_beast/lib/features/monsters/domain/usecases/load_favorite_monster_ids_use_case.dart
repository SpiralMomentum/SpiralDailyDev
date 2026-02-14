import 'package:utils/result/result.dart';

import '../repositories/favorite_monsters_repository.dart';

class LoadFavoriteMonsterIdsUseCase {
  const LoadFavoriteMonsterIdsUseCase({
    required FavoriteMonstersRepository repository,
  }) : _repository = repository;

  final FavoriteMonstersRepository _repository;

  Future<Result<Set<String>>> call() {
    return _repository.loadFavoriteIds();
  }
}
