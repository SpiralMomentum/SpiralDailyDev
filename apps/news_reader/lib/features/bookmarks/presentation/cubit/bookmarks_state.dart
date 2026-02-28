import 'package:equatable/equatable.dart';
import 'package:apps.news_reader/features/bookmarks/domain/entities/bookmark.dart';

enum BookmarksStatus { initial, loading, loaded, error }

class BookmarksState extends Equatable {
  const BookmarksState({
    this.status = BookmarksStatus.initial,
    this.bookmarks = const [],
    this.errorMessage,
  });

  final BookmarksStatus status;
  final List<Bookmark> bookmarks;
  final String? errorMessage;

  BookmarksState copyWith({
    BookmarksStatus? status,
    List<Bookmark>? bookmarks,
    String? Function()? errorMessage,
  }) {
    return BookmarksState(
      status: status ?? this.status,
      bookmarks: bookmarks ?? this.bookmarks,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, bookmarks, errorMessage];
}
