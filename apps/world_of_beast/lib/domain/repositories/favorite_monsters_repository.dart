abstract class FavoriteMonstersRepository {
  Future<Set<String>> loadFavoriteIds();
  Future<void> saveFavoriteIds(Set<String> ids);
}
