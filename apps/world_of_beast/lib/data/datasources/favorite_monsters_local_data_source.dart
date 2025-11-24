import 'package:shared_preferences/shared_preferences.dart';

class FavoriteMonstersLocalDataSource {
  const FavoriteMonstersLocalDataSource({
    this.preferences,
    this.storageKey = 'favoriteMonsterIds',
  });

  final SharedPreferences? preferences;
  final String storageKey;

  Future<Set<String>> loadFavoriteIds() async {
    final prefs = await _prefs;
    final stored = prefs.getStringList(storageKey);
    if (stored == null) {
      return const <String>{};
    }
    return stored.toSet();
  }

  Future<void> saveFavoriteIds(Set<String> ids) async {
    final prefs = await _prefs;
    final normalized = ids.toList()..sort();
    await prefs.setStringList(storageKey, normalized);
  }

  Future<SharedPreferences> get _prefs async {
    return preferences ?? SharedPreferences.getInstance();
  }
}
