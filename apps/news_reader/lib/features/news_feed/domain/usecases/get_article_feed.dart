import 'package:utils/result/result.dart';

import '../entities/article.dart';
import '../entities/paginated_articles.dart';
import '../repositories/article_repository.dart';

class GetArticleFeed {
  const GetArticleFeed(this._repository);

  final ArticleRepository _repository;

  Future<Result<PaginatedArticles>> call({
    ArticleCategory? category,
    String? cursor,
    int limit = 20,
  }) {
    return _repository.getArticleFeed(
      category: category,
      cursor: cursor,
      limit: limit,
    );
  }
}
