import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utils/result/result.dart';

import 'package:apps.news_reader/features/news_feed/domain/usecases/get_article_feed.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/toggle_bookmark.dart';
import 'news_feed_event.dart';
import 'news_feed_state.dart';

class NewsFeedBloc extends Bloc<NewsFeedEvent, NewsFeedState> {
  NewsFeedBloc({
    required GetArticleFeed getArticleFeed,
    required ToggleBookmark toggleBookmark,
  })  : _getArticleFeed = getArticleFeed,
        _toggleBookmark = toggleBookmark,
        super(const NewsFeedState()) {
    on<NewsFeedStarted>(_onStarted);
    on<NewsFeedRefreshed>(_onRefreshed);
    on<NewsFeedNextPageRequested>(_onNextPageRequested);
    on<NewsFeedCategoryChanged>(_onCategoryChanged);
    on<NewsFeedBookmarkToggled>(_onBookmarkToggled);
  }

  final GetArticleFeed _getArticleFeed;
  final ToggleBookmark _toggleBookmark;

  Future<void> _onStarted(
    NewsFeedStarted event,
    Emitter<NewsFeedState> emit,
  ) async {
    emit(state.copyWith(status: NewsFeedStatus.loading));
    await _fetchFeed(emit, isRefresh: true);
  }

  Future<void> _onRefreshed(
    NewsFeedRefreshed event,
    Emitter<NewsFeedState> emit,
  ) async {
    await _fetchFeed(emit, isRefresh: true);
  }

  Future<void> _onNextPageRequested(
    NewsFeedNextPageRequested event,
    Emitter<NewsFeedState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    await _fetchFeed(emit, isRefresh: false);
  }

  Future<void> _onCategoryChanged(
    NewsFeedCategoryChanged event,
    Emitter<NewsFeedState> emit,
  ) async {
    emit(state.copyWith(
      status: NewsFeedStatus.loading,
      selectedCategory: () => event.category,
      articles: [],
      nextCursor: () => null,
      hasMore: true,
    ));
    await _fetchFeed(emit, isRefresh: true);
  }

  Future<void> _onBookmarkToggled(
    NewsFeedBookmarkToggled event,
    Emitter<NewsFeedState> emit,
  ) async {
    final result = await _toggleBookmark(event.article);
    switch (result) {
      case Success(data: final isBookmarked):
        final updatedArticles = state.articles.map((a) {
          if (a.id == event.article.id) {
            return a.copyWith(isBookmarked: isBookmarked);
          }
          return a;
        }).toList();
        emit(state.copyWith(articles: updatedArticles));
      case ErrorResult():
        break;
    }
  }

  Future<void> _fetchFeed(
    Emitter<NewsFeedState> emit, {
    required bool isRefresh,
  }) async {
    final result = await _getArticleFeed(
      category: state.selectedCategory,
      cursor: isRefresh ? null : state.nextCursor,
    );

    switch (result) {
      case Success(data: final paginated):
        final articles = isRefresh
            ? paginated.articles
            : [...state.articles, ...paginated.articles];
        emit(state.copyWith(
          status: NewsFeedStatus.loaded,
          articles: articles,
          nextCursor: () => paginated.nextCursor,
          hasMore: paginated.hasMore,
          isLoadingMore: false,
          errorMessage: () => null,
        ));
      case ErrorResult(failure: final failure):
        emit(state.copyWith(
          status: NewsFeedStatus.error,
          errorMessage: () => failure.message,
          isLoadingMore: false,
        ));
    }
  }
}
