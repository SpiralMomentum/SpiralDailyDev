import '../../domain/entities/article.dart';
import '../../domain/entities/paginated_articles.dart';
import '../dto/article_dto.dart';
import '../dto/paginated_response_dto.dart';

class ArticleMapper {
  const ArticleMapper._();

  static Article toDomain(ArticleDto dto) {
    return Article(
      id: dto.id,
      title: dto.title,
      summary: dto.summary ?? '',
      content: dto.content ?? '',
      imageUrl: dto.imageUrl ?? '',
      category: _mapCategory(dto.category),
      isBookmarked: false,
      commentCount: dto.commentCount ?? 0,
      publishedAt: DateTime.tryParse(dto.publishedAt ?? '') ?? DateTime.now(),
      sourceName: dto.sourceName ?? 'Unknown',
    );
  }

  static PaginatedArticles toPaginatedDomain(PaginatedResponseDto dto) {
    return PaginatedArticles(
      articles: dto.items.map(toDomain).toList(),
      nextCursor: dto.nextCursor,
      hasMore: dto.hasMore,
    );
  }

  static ArticleCategory _mapCategory(String? raw) {
    if (raw == null) return ArticleCategory.unknown;
    return ArticleCategory.values.firstWhere(
      (e) => e.name == raw.toLowerCase(),
      orElse: () => ArticleCategory.unknown,
    );
  }
}
