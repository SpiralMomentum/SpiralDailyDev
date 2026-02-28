import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';
import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';
import 'package:apps.news_reader/features/news_feed/domain/entities/paginated_articles.dart';
import 'package:apps.news_reader/features/news_feed/domain/repositories/article_repository.dart';
import 'package:apps.news_reader/features/news_feed/domain/usecases/get_article_feed.dart';

class MockArticleRepository extends Mock implements ArticleRepository {}

void main() {
  late GetArticleFeed usecase;
  late MockArticleRepository repository;

  setUp(() {
    repository = MockArticleRepository();
    usecase = GetArticleFeed(repository);
  });

  final tPaginatedArticles = PaginatedArticles(
    articles: [
      Article(
        id: '1',
        title: 'Test Article',
        summary: 'Summary',
        content: 'Content',
        imageUrl: 'https://example.com/image.jpg',
        category: ArticleCategory.technology,
        isBookmarked: false,
        commentCount: 0,
        publishedAt: DateTime(2024, 1, 1),
        sourceName: 'Test Source',
      ),
    ],
    nextCursor: '1',
    hasMore: true,
  );

  group('GetArticleFeed', () {
    test('delegates to repository with correct parameters', () async {
      when(() => repository.getArticleFeed(
            category: any(named: 'category'),
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Success(tPaginatedArticles));

      final result = await usecase(
        category: ArticleCategory.technology,
        cursor: '0',
        limit: 10,
      );

      expect(result, isA<Success<PaginatedArticles>>());
      verify(() => repository.getArticleFeed(
            category: ArticleCategory.technology,
            cursor: '0',
            limit: 10,
          )).called(1);
    });

    test('returns ErrorResult when repository fails', () async {
      when(() => repository.getArticleFeed(
            category: any(named: 'category'),
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
          )).thenAnswer(
        (_) async => ErrorResult(NetworkFailure(message: 'Network error')),
      );

      final result = await usecase();

      expect(result, isA<ErrorResult<PaginatedArticles>>());
    });

    test('uses default limit of 20', () async {
      when(() => repository.getArticleFeed(
            category: any(named: 'category'),
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Success(tPaginatedArticles));

      await usecase();

      verify(() => repository.getArticleFeed(
            limit: 20,
          )).called(1);
    });
  });
}
