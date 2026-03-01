import 'package:equatable/equatable.dart';
import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';

enum NewsFeedStatus { initial, loading, loaded, error }

class NewsFeedState extends Equatable {
  const NewsFeedState({
    this.status = NewsFeedStatus.initial,
    this.articles = const [],
    this.selectedCategory,
    this.hasMore = true,
    this.nextCursor,
    this.errorMessage,
    this.isLoadingMore = false,
  });

  final NewsFeedStatus status;
  final List<Article> articles;
  final ArticleCategory? selectedCategory;
  final bool hasMore;
  final String? nextCursor;
  final String? errorMessage;
  final bool isLoadingMore;

  NewsFeedState copyWith({
    NewsFeedStatus? status,
    List<Article>? articles,
    ArticleCategory? Function()? selectedCategory,
    bool? hasMore,
    String? Function()? nextCursor,
    String? Function()? errorMessage,
    bool? isLoadingMore,
  }) {
    return NewsFeedState(
      status: status ?? this.status,
      articles: articles ?? this.articles,
      selectedCategory: selectedCategory != null ? selectedCategory() : this.selectedCategory,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [status, articles, selectedCategory, hasMore, nextCursor, errorMessage, isLoadingMore];
}
