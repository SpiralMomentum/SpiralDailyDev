import 'package:app_logging/app_logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteMonstersLocalDataSource {
  FavoriteMonstersLocalDataSource({
    this.preferences,
    this.storageKey = 'favoriteMonsterIds',
  });

  final SharedPreferences? preferences;
  final String storageKey;

  final _logger = AppLogger(tag: 'FavoriteMonstersLocalDataSource');

  Future<Set<String>> loadFavoriteIds() async {
    try {
      final prefs = await _prefs;
      final stored = prefs.getStringList(storageKey);
      if (stored == null) {
        return const <String>{};
      }
      return stored.toSet();
    } catch (error, stackTrace) {
      _logger.error(
        '즐겨찾기 ID 읽기 실패 (key: $storageKey)',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> saveFavoriteIds(Set<String> ids) async {
    try {
      final prefs = await _prefs;
      final normalized = ids.toList()..sort();
      await prefs.setStringList(storageKey, normalized);
    } catch (error, stackTrace) {
      _logger.error(
        '즐겨찾기 ID 저장 실패 (key: $storageKey, count: ${ids.length})',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<SharedPreferences> get _prefs async {
    return preferences ?? SharedPreferences.getInstance();
  }
}
