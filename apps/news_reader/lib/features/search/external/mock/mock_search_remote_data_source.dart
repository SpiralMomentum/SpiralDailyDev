import 'package:apps.news_reader/features/news_feed/data/datasources/article_remote_data_source.dart';
import 'package:apps.news_reader/features/news_feed/data/dto/article_dto.dart';
import 'package:apps.news_reader/features/news_feed/data/dto/paginated_response_dto.dart';

class MockSearchRemoteDataSource implements ArticleRemoteDataSource {
  static final List<ArticleDto> _staticArticles = [
    const ArticleDto(
      id: 'search-1',
      title: 'Flutter 4.0 Released with Major Performance Improvements',
      summary: 'Google announces Flutter 4.0 with significant rendering speed gains.',
      content: 'Full article content about Flutter 4.0...',
      imageUrl: 'https://example.com/flutter.png',
      category: 'technology',
      commentCount: 42,
      publishedAt: '2024-01-15T10:00:00Z',
      sourceName: 'TechCrunch',
    ),
    const ArticleDto(
      id: 'search-2',
      title: 'Dart Language Gets New Macro System',
      summary: 'The Dart team introduces a powerful macro system for metaprogramming.',
      content: 'Full article content about Dart macros...',
      imageUrl: 'https://example.com/dart.png',
      category: 'technology',
      commentCount: 28,
      publishedAt: '2024-01-14T09:00:00Z',
      sourceName: 'Medium',
    ),
    const ArticleDto(
      id: 'search-3',
      title: 'Stock Market Reaches All-Time High',
      summary: 'Major indices surge as tech sector leads rally.',
      content: 'Full article content about stock market...',
      imageUrl: 'https://example.com/stocks.png',
      category: 'business',
      commentCount: 15,
      publishedAt: '2024-01-13T08:00:00Z',
      sourceName: 'Bloomberg',
    ),
    const ArticleDto(
      id: 'search-4',
      title: 'New AI Research Breakthrough in Healthcare',
      summary: 'Scientists develop AI model that detects diseases earlier than ever.',
      content: 'Full article content about AI healthcare...',
      imageUrl: 'https://example.com/ai.png',
      category: 'science',
      commentCount: 56,
      publishedAt: '2024-01-12T07:00:00Z',
      sourceName: 'Nature',
    ),
    const ArticleDto(
      id: 'search-5',
      title: 'Mobile Development Trends for 2024',
      summary: 'Flutter and Kotlin Multiplatform lead the cross-platform development space.',
      content: 'Full article content about mobile dev trends...',
      imageUrl: 'https://example.com/mobile.png',
      category: 'technology',
      commentCount: 33,
      publishedAt: '2024-01-11T06:00:00Z',
      sourceName: 'InfoQ',
    ),
  ];

  @override
  Future<PaginatedResponseDto> getArticleFeed({
    String? category,
    String? cursor,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var articles = _staticArticles;
    if (category != null) {
      articles = articles.where((a) => a.category == category).toList();
    }

    int startIndex = 0;
    if (cursor != null) {
      startIndex = int.tryParse(cursor) ?? 0;
    }

    final endIndex = (startIndex + limit).clamp(0, articles.length);
    final pageItems = articles.sublist(
      startIndex.clamp(0, articles.length),
      endIndex,
    );

    final hasMore = endIndex < articles.length;
    final nextCursor = hasMore ? endIndex.toString() : null;

    return PaginatedResponseDto(
      items: pageItems,
      nextCursor: nextCursor,
      hasMore: hasMore,
    );
  }

  @override
  Future<ArticleDto> getArticleDetail(String articleId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return _staticArticles.firstWhere(
      (a) => a.id == articleId,
      orElse: () => throw Exception('Article not found: $articleId'),
    );
  }
}
