import 'package:flutter_test/flutter_test.dart';
import 'package:apps.news_reader/features/news_feed/data/dto/article_dto.dart';
import 'package:apps.news_reader/features/news_feed/data/dto/paginated_response_dto.dart';
import 'package:apps.news_reader/features/news_feed/data/mappers/article_mapper.dart';
import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';

void main() {
  group('ArticleMapper', () {
    group('toDomain', () {
      test('maps all fields correctly', () {
        final dto = ArticleDto(
          id: '1',
          title: 'Title',
          summary: 'Summary',
          content: 'Content',
          imageUrl: 'https://img.com/1.jpg',
          category: 'technology',
          commentCount: 5,
          publishedAt: '2024-01-01T00:00:00Z',
          sourceName: 'TechNews',
        );

        final article = ArticleMapper.toDomain(dto);

        expect(article.id, '1');
        expect(article.title, 'Title');
        expect(article.summary, 'Summary');
        expect(article.content, 'Content');
        expect(article.imageUrl, 'https://img.com/1.jpg');
        expect(article.category, ArticleCategory.technology);
        expect(article.isBookmarked, false);
        expect(article.commentCount, 5);
        expect(article.sourceName, 'TechNews');
      });

      test('handles null optional fields', () {
        final dto = ArticleDto(id: '1', title: 'Title');

        final article = ArticleMapper.toDomain(dto);

        expect(article.summary, '');
        expect(article.content, '');
        expect(article.imageUrl, '');
        expect(article.category, ArticleCategory.unknown);
        expect(article.commentCount, 0);
        expect(article.sourceName, 'Unknown');
      });

      test('maps unknown category to ArticleCategory.unknown', () {
        final dto = ArticleDto(
          id: '1',
          title: 'Title',
          category: 'nonexistent',
        );

        final article = ArticleMapper.toDomain(dto);

        expect(article.category, ArticleCategory.unknown);
      });
    });

    group('toPaginatedDomain', () {
      test('maps paginated response correctly', () {
        final dto = PaginatedResponseDto(
          items: [
            ArticleDto(id: '1', title: 'A'),
            ArticleDto(id: '2', title: 'B'),
          ],
          nextCursor: '2',
          hasMore: true,
        );

        final result = ArticleMapper.toPaginatedDomain(dto);

        expect(result.articles.length, 2);
        expect(result.nextCursor, '2');
        expect(result.hasMore, true);
      });
    });
  });
}
