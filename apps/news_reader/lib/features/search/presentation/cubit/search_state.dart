import 'package:equatable/equatable.dart';

import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';

enum SearchStatus { initial, loading, loaded, error }

class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.initial,
    this.articles = const [],
    this.searchHistory = const [],
    this.query = '',
    this.hasMore = false,
    this.cursor,
    this.errorMessage,
  });

  final SearchStatus status;
  final List<Article> articles;
  final List<String> searchHistory;
  final String query;
  final bool hasMore;
  final String? cursor;
  final String? errorMessage;

  SearchState copyWith({
    SearchStatus? status,
    List<Article>? articles,
    List<String>? searchHistory,
    String? query,
    bool? hasMore,
    String? Function()? cursor,
    String? Function()? errorMessage,
  }) {
    return SearchState(
      status: status ?? this.status,
      articles: articles ?? this.articles,
      searchHistory: searchHistory ?? this.searchHistory,
      query: query ?? this.query,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor != null ? cursor() : this.cursor,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        articles,
        searchHistory,
        query,
        hasMore,
        cursor,
        errorMessage,
      ];
}
