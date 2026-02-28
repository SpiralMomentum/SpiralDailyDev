import '../dto/article_dto.dart';
import '../dto/paginated_response_dto.dart';

abstract class ArticleRemoteDataSource {
  Future<PaginatedResponseDto> getArticleFeed({
    String? category,
    String? cursor,
    int limit = 20,
  });

  Future<ArticleDto> getArticleDetail(String articleId);
}
