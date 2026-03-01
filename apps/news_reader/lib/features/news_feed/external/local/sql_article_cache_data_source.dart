import 'dart:convert';

import 'package:apps.news_reader/features/news_feed/data/datasources/article_local_data_source.dart';
import 'package:apps.news_reader/features/news_feed/data/dto/paginated_response_dto.dart';
import 'package:sqflite/sqflite.dart';

class SqlArticleCacheDataSource implements ArticleLocalDataSource {
  SqlArticleCacheDataSource(this._db);

  final Database _db;

  static const _tableName = 'article_cache';
  static const _defaultTtlMs = 300000; // 5 minutes

  @override
  Future<PaginatedResponseDto?> getCachedFeed(String cacheKey) async {
    await clearExpiredCache();
    final rows = await _db.query(
      _tableName,
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final cachedAt = row['cached_at'] as int;
    final ttlMs = row['ttl_ms'] as int? ?? _defaultTtlMs;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - cachedAt > ttlMs) {
      await _db.delete(
        _tableName,
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
      );
      return null;
    }

    final json =
        jsonDecode(row['response_json'] as String) as Map<String, dynamic>;
    return PaginatedResponseDto.fromJson(json);
  }

  @override
  Future<void> cacheFeed(
    String cacheKey,
    PaginatedResponseDto response,
  ) async {
    final json = jsonEncode(response.toJson());
    await _db.insert(
      _tableName,
      {
        'cache_key': cacheKey,
        'response_json': json,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
        'ttl_ms': _defaultTtlMs,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clearExpiredCache() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.rawDelete(
      'DELETE FROM $_tableName WHERE (? - cached_at) > ttl_ms',
      [now],
    );
  }
}
