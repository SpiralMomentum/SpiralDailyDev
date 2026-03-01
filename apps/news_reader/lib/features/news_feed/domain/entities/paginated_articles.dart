import 'package:equatable/equatable.dart';

import 'article.dart';

class PaginatedArticles extends Equatable {
  const PaginatedArticles({
    required this.articles,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<Article> articles;
  final String? nextCursor;
  final bool hasMore;

  @override
  List<Object?> get props => [articles, nextCursor, hasMore];
}
