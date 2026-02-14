import 'package:utils/result/result.dart';

abstract class FavoriteMonstersRepository {
  Future<Result<Set<String>>> loadFavoriteIds();
  Future<Result<void>> saveFavoriteIds(Set<String> ids);
}
