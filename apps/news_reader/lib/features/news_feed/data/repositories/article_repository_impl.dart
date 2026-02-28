import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';

import '../../domain/entities/article.dart';
import '../../domain/entities/paginated_articles.dart';
import '../../domain/repositories/article_repository.dart';
import '../datasources/article_local_data_source.dart';
import '../datasources/article_remote_data_source.dart';
import '../mappers/article_mapper.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  const ArticleRepositoryImpl({
    required ArticleRemoteDataSource remoteDataSource,
    required ArticleLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final ArticleRemoteDataSource _remoteDataSource;
  final ArticleLocalDataSource _localDataSource;

  @override
  Future<Result<PaginatedArticles>> getArticleFeed({
    ArticleCategory? category,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final cacheKey = 'feed:${category?.name ?? 'all'}:${cursor ?? 'first'}';

      // Check cache first
      final cached = await _localDataSource.getCachedFeed(cacheKey);
      if (cached != null) {
        return Success(ArticleMapper.toPaginatedDomain(cached));
      }

      // Fetch from remote
      final response = await _remoteDataSource.getArticleFeed(
        category: category?.name,
        cursor: cursor,
        limit: limit,
      );

      // Cache the response
      await _localDataSource.cacheFeed(cacheKey, response);

      return Success(ArticleMapper.toPaginatedDomain(response));
    } catch (e, st) {
      return ErrorResult(
        NetworkFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Article>> getArticleDetail(String articleId) async {
    try {
      final dto = await _remoteDataSource.getArticleDetail(articleId);
      return Success(ArticleMapper.toDomain(dto));
    } catch (e, st) {
      return ErrorResult(
        NetworkFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
