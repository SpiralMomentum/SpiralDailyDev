import 'package:sqflite/sqflite.dart';

import 'package:apps.news_reader/core/db/database_helper.dart';

import '../../data/datasources/bookmark_local_data_source.dart';

class SqlBookmarkLocalDataSource implements BookmarkLocalDataSource {
  @override
  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final db = await DatabaseHelper.database;
    return db.query(
      'bookmarks',
      where: "sync_status != ?",
      whereArgs: ['pendingDelete'],
      orderBy: 'saved_at DESC',
    );
  }

  @override
  Future<void> insertBookmark(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.database;
    await db.insert(
      'bookmarks',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteBookmark(String articleId) async {
    final db = await DatabaseHelper.database;
    await db.delete(
      'bookmarks',
      where: 'article_id = ?',
      whereArgs: [articleId],
    );
  }

  @override
  Future<bool> isBookmarked(String articleId) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS cnt FROM bookmarks WHERE article_id = ? AND sync_status != 'pendingDelete'",
      [articleId],
    );
    final count = result.first['cnt'] as int;
    return count > 0;
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingBookmarks() async {
    final db = await DatabaseHelper.database;
    return db.query(
      'bookmarks',
      where: "sync_status IN (?, ?)",
      whereArgs: ['pendingUpload', 'pendingDelete'],
    );
  }

  @override
  Future<void> updateSyncStatus(
    String articleId,
    String syncStatus,
    int version,
  ) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'bookmarks',
      {
        'sync_status': syncStatus,
        'version': version,
        'updated_at': now,
      },
      where: 'article_id = ?',
      whereArgs: [articleId],
    );
  }
}
