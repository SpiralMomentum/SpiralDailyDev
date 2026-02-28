import '../../data/datasources/bookmark_local_data_source.dart';

/// In-memory implementation for Phase 1.
/// Will be replaced with sqflite implementation in Phase 2.
class InMemoryBookmarkLocalDataSource implements BookmarkLocalDataSource {
  final List<Map<String, dynamic>> _bookmarks = [];

  @override
  Future<List<Map<String, dynamic>>> getBookmarks() async {
    return List.unmodifiable(
      _bookmarks..sort((a, b) =>
          (b['saved_at'] as int).compareTo(a['saved_at'] as int)),
    );
  }

  @override
  Future<void> insertBookmark(Map<String, dynamic> data) async {
    // Remove existing if present (upsert)
    _bookmarks.removeWhere(
        (b) => b['article_id'] == data['article_id']);
    _bookmarks.add(Map.from(data));
  }

  @override
  Future<void> deleteBookmark(String articleId) async {
    _bookmarks
        .removeWhere((b) => b['article_id'] == articleId);
  }

  @override
  Future<bool> isBookmarked(String articleId) async {
    return _bookmarks
        .any((b) => b['article_id'] == articleId);
  }
}
