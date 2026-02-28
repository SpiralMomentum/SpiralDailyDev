import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';

import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';
import 'package:apps.news_reader/features/news_feed/domain/entities/paginated_articles.dart';
import 'package:apps.news_reader/features/search/domain/repositories/search_repository.dart';
import 'package:apps.news_reader/features/search/domain/usecases/search_articles.dart';

class MockSearchRepository extends Mock implements SearchRepository {}

void main() {
  late SearchArticles usecase;
  late MockSearchRepository mockRepository;

  setUp(() {
    mockRepository = MockSearchRepository();
    usecase = SearchArticles(mockRepository);
  });

  final tArticles = PaginatedArticles(
    articles: [
      Article(
        id: '1',
        title: 'Flutter News',
        summary: 'Flutter update summary',
        content: 'Content',
        imageUrl: 'https://example.com/img.png',
        category: ArticleCategory.technology,
        isBookmarked: false,
        commentCount: 10,
        publishedAt: DateTime(2024, 1, 15),
        sourceName: 'TechCrunch',
      ),
    ],
    nextCursor: null,
    hasMore: false,
  );

  group('SearchArticles', () {
    test('delegates to repository with correct parameters', () async {
      when(() => mockRepository.searchArticles(
            query: 'flutter',
            cursor: null,
            limit: 20,
          )).thenAnswer((_) async => Success(tArticles));

      final result = await usecase(query: 'flutter');

      expect(result, isA<Success<PaginatedArticles>>());
      verify(() => mockRepository.searchArticles(
            query: 'flutter',
            cursor: null,
            limit: 20,
          )).called(1);
    });

    test('passes cursor and limit to repository', () async {
      when(() => mockRepository.searchArticles(
            query: 'dart',
            cursor: '10',
            limit: 5,
          )).thenAnswer((_) async => Success(tArticles));

      final result = await usecase(query: 'dart', cursor: '10', limit: 5);

      expect(result, isA<Success<PaginatedArticles>>());
      verify(() => mockRepository.searchArticles(
            query: 'dart',
            cursor: '10',
            limit: 5,
          )).called(1);
    });
  });
}
