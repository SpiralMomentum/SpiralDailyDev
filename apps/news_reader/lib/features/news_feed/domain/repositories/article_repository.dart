import 'package:utils/result/result.dart';

import '../entities/article.dart';
import '../entities/paginated_articles.dart';

abstract class ArticleRepository {
  Future<Result<PaginatedArticles>> getArticleFeed({
    ArticleCategory? category,
    String? cursor,
    int limit = 20,
  });

  Future<Result<Article>> getArticleDetail(String articleId);
}
