import '../../domain/entities/bookmark.dart';

class BookmarkMapper {
  const BookmarkMapper._();

  static Bookmark toDomain(Map<String, dynamic> row) {
    return Bookmark(
      articleId: row['article_id'] as String,
      title: row['title'] as String,
      summary: row['summary'] as String? ?? '',
      content: row['content'] as String? ?? '',
      imageUrl: row['image_url'] as String? ?? '',
      category: row['category'] as String? ?? 'general',
      savedAt: DateTime.fromMillisecondsSinceEpoch(row['saved_at'] as int),
      syncStatus: _mapSyncStatus(row['sync_status'] as String?),
      highlightedText: row['highlighted_text'] as String?,
    );
  }

  static Map<String, dynamic> toMap(Bookmark bookmark) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'article_id': bookmark.articleId,
      'title': bookmark.title,
      'summary': bookmark.summary,
      'content': bookmark.content,
      'image_url': bookmark.imageUrl,
      'category': bookmark.category,
      'saved_at': bookmark.savedAt.millisecondsSinceEpoch,
      'sync_status': bookmark.syncStatus.name,
      'version': 1,
      'created_at': now,
      'updated_at': now,
    };
  }

  static SyncStatus _mapSyncStatus(String? raw) {
    if (raw == null) return SyncStatus.synced;
    return SyncStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => SyncStatus.synced,
    );
  }
}
