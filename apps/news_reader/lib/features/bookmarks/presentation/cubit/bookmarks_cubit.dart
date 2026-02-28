import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utils/result/result.dart';

import 'package:apps.news_reader/features/bookmarks/domain/usecases/get_bookmarks.dart';
import 'package:apps.news_reader/features/bookmarks/domain/usecases/toggle_bookmark.dart';
import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';
import 'package:apps.news_reader/features/bookmarks/domain/entities/bookmark.dart';
import 'bookmarks_state.dart';

class BookmarksCubit extends Cubit<BookmarksState> {
  BookmarksCubit({
    required GetBookmarks getBookmarks,
    required ToggleBookmark toggleBookmark,
  })  : _getBookmarks = getBookmarks,
        _toggleBookmark = toggleBookmark,
        super(const BookmarksState());

  final GetBookmarks _getBookmarks;
  final ToggleBookmark _toggleBookmark;

  Future<void> loadBookmarks() async {
    emit(state.copyWith(status: BookmarksStatus.loading));

    final result = await _getBookmarks();
    switch (result) {
      case Success(data: final bookmarks):
        emit(state.copyWith(
          status: BookmarksStatus.loaded,
          bookmarks: bookmarks,
          errorMessage: () => null,
        ));
      case ErrorResult(failure: final failure):
        emit(state.copyWith(
          status: BookmarksStatus.error,
          errorMessage: () => failure.message,
        ));
    }
  }

  Future<void> removeBookmark(Bookmark bookmark) async {
    final article = Article(
      id: bookmark.articleId,
      title: bookmark.title,
      summary: bookmark.summary,
      content: bookmark.content,
      imageUrl: bookmark.imageUrl,
      category: _parseCategory(bookmark.category),
      isBookmarked: true,
      commentCount: 0,
      publishedAt: bookmark.savedAt,
      sourceName: '',
    );

    final result = await _toggleBookmark(article);
    switch (result) {
      case Success():
        await loadBookmarks();
      case ErrorResult():
        break;
    }
  }

  ArticleCategory _parseCategory(String name) {
    return ArticleCategory.values.firstWhere(
      (c) => c.name == name,
      orElse: () => ArticleCategory.technology,
    );
  }
}
