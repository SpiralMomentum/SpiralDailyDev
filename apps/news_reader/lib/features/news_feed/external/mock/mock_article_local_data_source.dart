import '../../data/datasources/article_local_data_source.dart';
import '../../data/dto/paginated_response_dto.dart';

class MockArticleLocalDataSource implements ArticleLocalDataSource {
  final Map<String, _CacheEntry> _cache = {};
  static const _ttlMs = 300000; // 5 minutes

  @override
  Future<PaginatedResponseDto?> getCachedFeed(String cacheKey) async {
    final entry = _cache[cacheKey];
    if (entry == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - entry.cachedAt > _ttlMs) {
      _cache.remove(cacheKey);
      return null;
    }

    return entry.response;
  }

  @override
  Future<void> cacheFeed(
      String cacheKey, PaginatedResponseDto response) async {
    _cache[cacheKey] = _CacheEntry(
      response: response,
      cachedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> clearExpiredCache() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _cache.removeWhere((_, entry) => now - entry.cachedAt > _ttlMs);
  }
}

class _CacheEntry {
  const _CacheEntry({required this.response, required this.cachedAt});
  final PaginatedResponseDto response;
  final int cachedAt;
}
