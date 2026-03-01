import 'package:utils/result/result.dart';

import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';
import 'package:apps.news_reader/features/news_feed/domain/repositories/article_repository.dart';

class GetArticleDetail {
  const GetArticleDetail(this._repository);

  final ArticleRepository _repository;

  Future<Result<Article>> call(String articleId) {
    return _repository.getArticleDetail(articleId);
  }
}
