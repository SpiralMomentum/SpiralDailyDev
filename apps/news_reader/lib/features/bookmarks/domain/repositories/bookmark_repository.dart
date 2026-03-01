import 'package:utils/result/result.dart';

import '../entities/bookmark.dart';

abstract class BookmarkRepository {
  Future<Result<List<Bookmark>>> getBookmarks();
  Future<Result<Bookmark>> addBookmark(Bookmark bookmark);
  Future<Result<void>> removeBookmark(String articleId);
  Future<Result<bool>> isBookmarked(String articleId);
  Future<Result<List<Bookmark>>> getPendingBookmarks();
  Future<Result<int>> syncBookmarks();
  Future<Result<void>> updateSyncStatus(
      String articleId, SyncStatus status, int version);
}
