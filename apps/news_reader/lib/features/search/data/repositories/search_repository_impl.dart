import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';

import 'package:apps.news_reader/features/news_feed/domain/entities/paginated_articles.dart';
import 'package:apps.news_reader/features/news_feed/data/datasources/article_remote_data_source.dart';
import 'package:apps.news_reader/features/news_feed/data/mappers/article_mapper.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_history_data_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl({
    required ArticleRemoteDataSource remoteDataSource,
    required SearchHistoryDataSource historyDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _historyDataSource = historyDataSource;

  final ArticleRemoteDataSource _remoteDataSource;
  final SearchHistoryDataSource _historyDataSource;

  @override
  Future<Result<PaginatedArticles>> searchArticles({
    required String query,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final response = await _remoteDataSource.getArticleFeed(
        cursor: cursor,
        limit: limit,
      );

      final allArticles = ArticleMapper.toPaginatedDomain(response);

      final lowerQuery = query.toLowerCase();
      final filtered = allArticles.articles.where((article) {
        return article.title.toLowerCase().contains(lowerQuery) ||
            article.summary.toLowerCase().contains(lowerQuery);
      }).toList();

      return Success(PaginatedArticles(
        articles: filtered,
        nextCursor: allArticles.nextCursor,
        hasMore: allArticles.hasMore,
      ));
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
  Future<Result<List<String>>> getSearchHistory() async {
    try {
      final entries = await _historyDataSource.getSearchHistory();
      final queries = entries
          .map((e) => e['query'] as String)
          .toList();
      return Success(queries);
    } catch (e, st) {
      return ErrorResult(
        LocalStorageFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> saveSearchQuery(String query) async {
    try {
      await _historyDataSource.saveSearchQuery({
        'query': query,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return const Success(null);
    } catch (e, st) {
      return ErrorResult(
        LocalStorageFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> clearSearchHistory() async {
    try {
      await _historyDataSource.clearSearchHistory();
      return const Success(null);
    } catch (e, st) {
      return ErrorResult(
        LocalStorageFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
