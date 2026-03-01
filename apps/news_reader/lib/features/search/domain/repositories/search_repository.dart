import 'package:utils/result/result.dart';

import 'package:apps.news_reader/features/news_feed/domain/entities/paginated_articles.dart';

abstract class SearchRepository {
  Future<Result<PaginatedArticles>> searchArticles({
    required String query,
    String? cursor,
    int limit = 20,
  });

  Future<Result<List<String>>> getSearchHistory();

  Future<Result<void>> saveSearchQuery(String query);

  Future<Result<void>> clearSearchHistory();
}
