import '../dto/paginated_response_dto.dart';

abstract class ArticleLocalDataSource {
  Future<PaginatedResponseDto?> getCachedFeed(String cacheKey);
  Future<void> cacheFeed(String cacheKey, PaginatedResponseDto response);
  Future<void> clearExpiredCache();
}
