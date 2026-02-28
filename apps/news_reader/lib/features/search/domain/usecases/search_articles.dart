import 'package:utils/result/result.dart';

import 'package:apps.news_reader/features/news_feed/domain/entities/paginated_articles.dart';
import '../repositories/search_repository.dart';

class SearchArticles {
  const SearchArticles(this._repository);

  final SearchRepository _repository;

  Future<Result<PaginatedArticles>> call({
    required String query,
    String? cursor,
    int limit = 20,
  }) {
    return _repository.searchArticles(
      query: query,
      cursor: cursor,
      limit: limit,
    );
  }
}
