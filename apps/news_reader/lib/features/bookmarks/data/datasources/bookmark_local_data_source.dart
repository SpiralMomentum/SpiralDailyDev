abstract class BookmarkLocalDataSource {
  Future<List<Map<String, dynamic>>> getBookmarks();
  Future<void> insertBookmark(Map<String, dynamic> data);
  Future<void> deleteBookmark(String articleId);
  Future<bool> isBookmarked(String articleId);
}
