import 'article_dto.dart';

class PaginatedResponseDto {
  const PaginatedResponseDto({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  final List<ArticleDto> items;
  final String? nextCursor;
  final bool hasMore;

  factory PaginatedResponseDto.fromJson(Map<String, dynamic> json) {
    return PaginatedResponseDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => ArticleDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['next_cursor'] as String?,
      hasMore: json['has_more'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'next_cursor': nextCursor,
        'has_more': hasMore,
      };
}
