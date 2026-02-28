import 'dart:convert';

import 'package:flutter/services.dart';

import '../../data/datasources/article_remote_data_source.dart';
import '../../data/dto/article_dto.dart';
import '../../data/dto/paginated_response_dto.dart';

class MockArticleRemoteDataSource implements ArticleRemoteDataSource {
  PaginatedResponseDto? _cachedResponse;

  @override
  Future<PaginatedResponseDto> getArticleFeed({
    String? category,
    String? cursor,
    int limit = 20,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final response = await _loadMockData();

    var articles = response.items;
    if (category != null) {
      articles =
          articles.where((a) => a.category == category).toList();
    }

    // Simulate cursor-based pagination
    int startIndex = 0;
    if (cursor != null) {
      startIndex = int.tryParse(cursor) ?? 0;
    }

    final endIndex =
        (startIndex + limit).clamp(0, articles.length);
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
    await Future.delayed(const Duration(milliseconds: 500));

    final response = await _loadMockData();
    return response.items.firstWhere(
      (a) => a.id == articleId,
      orElse: () => throw Exception('Article not found: $articleId'),
    );
  }

  Future<PaginatedResponseDto> _loadMockData() async {
    if (_cachedResponse != null) return _cachedResponse!;

    final jsonString =
        await rootBundle.loadString('assets/mock/articles.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    _cachedResponse = PaginatedResponseDto.fromJson(json);
    return _cachedResponse!;
  }
}
