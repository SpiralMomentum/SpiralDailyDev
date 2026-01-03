import 'package:flutter/foundation.dart';

import '../../domain/entities/monster.dart';
import '../../domain/usecases/load_favorite_monster_ids_use_case.dart';
import '../../domain/usecases/save_favorite_monster_ids_use_case.dart';

class MonsterFavoritesController extends ChangeNotifier {
  MonsterFavoritesController({
    required LoadFavoriteMonsterIdsUseCase loadFavorites,
    required SaveFavoriteMonsterIdsUseCase saveFavorites,
  })  : _loadFavorites = loadFavorites,
        _saveFavorites = saveFavorites;

  final LoadFavoriteMonsterIdsUseCase _loadFavorites;
  final SaveFavoriteMonsterIdsUseCase _saveFavorites;

  Set<String> _favoriteIds = const <String>{};
  bool _hasLoaded = false;

  bool get isReady => _hasLoaded;

  Set<String> get favoriteIds => _favoriteIds;

  Future<void> initialize() async {
    if (_hasLoaded) {
      return;
    }
    try {
      final ids = await _loadFavorites();
      _favoriteIds = Set<String>.unmodifiable(ids);
    } catch (_) {
      _favoriteIds = const <String>{};
    }
    _hasLoaded = true;
    notifyListeners();
  }

  bool isFavorite(String id) {
    return _favoriteIds.contains(id);
  }

  Future<bool> toggleFavorite(String id) async {
    final updated = Set<String>.from(_favoriteIds);
    final bool isNowFavorite;
    if (updated.contains(id)) {
      updated.remove(id);
      isNowFavorite = false;
    } else {
      updated.add(id);
      isNowFavorite = true;
    }
    _favoriteIds = Set<String>.unmodifiable(updated);
    notifyListeners();
    await _persistFavorites();
    return isNowFavorite;
  }

  Future<void> removeFavorite(String id) {
    if (!isFavorite(id)) {
      return Future.value();
    }
    final updated = Set<String>.from(_favoriteIds)..remove(id);
    _favoriteIds = Set<String>.unmodifiable(updated);
    notifyListeners();
    return _persistFavorites();
  }

  List<Monster> filterFavorites(Iterable<Monster> monsters) {
    if (_favoriteIds.isEmpty) {
      return const [];
    }
    final favorites = monsters
        .where((monster) => _favoriteIds.contains(monster.id))
        .toList();
    favorites.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return favorites;
  }

  Future<void> pruneUnknownFavorites(Set<String> validIds) async {
    if (_favoriteIds.isEmpty) {
      return;
    }
    final filtered = _favoriteIds.where(validIds.contains).toSet();
    if (filtered.length == _favoriteIds.length) {
      return;
    }
    _favoriteIds = Set<String>.unmodifiable(filtered);
    notifyListeners();
    await _persistFavorites();
  }

  Future<void> _persistFavorites() {
    return _saveFavorites(_favoriteIds);
  }
}
