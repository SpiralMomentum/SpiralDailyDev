import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utils/result/result.dart';

import 'package:apps.news_reader/features/article_detail/domain/usecases/get_article_detail.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/toggle_bookmark.dart';
import 'article_detail_event.dart';
import 'article_detail_state.dart';

class ArticleDetailBloc extends Bloc<ArticleDetailEvent, ArticleDetailState> {
  ArticleDetailBloc({
    required GetArticleDetail getArticleDetail,
    required ToggleBookmark toggleBookmark,
  })  : _getArticleDetail = getArticleDetail,
        _toggleBookmark = toggleBookmark,
        super(const ArticleDetailState()) {
    on<ArticleDetailStarted>(_onStarted);
    on<ArticleDetailBookmarkToggled>(_onBookmarkToggled);
    on<ArticleDetailRefreshed>(_onRefreshed);
  }

  final GetArticleDetail _getArticleDetail;
  final ToggleBookmark _toggleBookmark;
  String? _articleId;

  Future<void> _onStarted(
    ArticleDetailStarted event,
    Emitter<ArticleDetailState> emit,
  ) async {
    _articleId = event.articleId;
    emit(state.copyWith(status: ArticleDetailStatus.loading));
    await _fetchDetail(emit);
  }

  Future<void> _onRefreshed(
    ArticleDetailRefreshed event,
    Emitter<ArticleDetailState> emit,
  ) async {
    await _fetchDetail(emit);
  }

  Future<void> _onBookmarkToggled(
    ArticleDetailBookmarkToggled event,
    Emitter<ArticleDetailState> emit,
  ) async {
    final article = state.article;
    if (article == null) return;

    final result = await _toggleBookmark(article);
    switch (result) {
      case Success(data: final isBookmarked):
        emit(state.copyWith(
          article: article.copyWith(isBookmarked: isBookmarked),
        ));
      case ErrorResult():
        break;
    }
  }

  Future<void> _fetchDetail(Emitter<ArticleDetailState> emit) async {
    if (_articleId == null) return;

    final result = await _getArticleDetail(_articleId!);
    switch (result) {
      case Success(data: final article):
        emit(state.copyWith(
          status: ArticleDetailStatus.loaded,
          article: article,
          errorMessage: () => null,
        ));
      case ErrorResult(failure: final failure):
        emit(state.copyWith(
          status: ArticleDetailStatus.error,
          errorMessage: () => failure.message,
        ));
    }
  }
}
