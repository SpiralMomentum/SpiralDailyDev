import 'package:apps.news_reader/features/news_feed/data/dto/article_dto.dart';
import 'package:apps.news_reader/features/news_feed/data/dto/paginated_response_dto.dart';
import 'package:apps.news_reader/features/news_feed/external/local/sql_article_cache_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _createInMemoryDb() async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE article_cache (
            cache_key TEXT PRIMARY KEY,
            response_json TEXT NOT NULL,
            cached_at INTEGER NOT NULL,
            ttl_ms INTEGER NOT NULL
          )
        ''');
      },
    ),
  );
  return db;
}

PaginatedResponseDto _createSampleResponse({
  String articleId = 'a1',
  String title = 'Test Article',
}) {
  return PaginatedResponseDto(
    items: [
      ArticleDto(
        id: articleId,
        title: title,
        summary: 'Summary',
        category: 'tech',
        commentCount: 5,
        publishedAt: '2025-01-01T00:00:00Z',
        sourceName: 'TestSource',
      ),
    ],
    nextCursor: 'cursor_2',
    hasMore: true,
  );
}

void main() {
  sqfliteFfiInit();

  late Database db;
  late SqlArticleCacheDataSource dataSource;

  setUp(() async {
    db = await _createInMemoryDb();
    dataSource = SqlArticleCacheDataSource(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SqlArticleCacheDataSource', () {
    test('returns null for cache miss', () async {
      final result = await dataSource.getCachedFeed('non_existent_key');
      expect(result, isNull);
    });

    test('stores and retrieves cached feed', () async {
      final response = _createSampleResponse();
      const cacheKey = 'feed_tech';

      await dataSource.cacheFeed(cacheKey, response);
      final result = await dataSource.getCachedFeed(cacheKey);

      expect(result, isNotNull);
      expect(result!.items.length, equals(1));
      expect(result.items.first.id, equals('a1'));
      expect(result.items.first.title, equals('Test Article'));
      expect(result.items.first.summary, equals('Summary'));
      expect(result.items.first.category, equals('tech'));
      expect(result.items.first.commentCount, equals(5));
      expect(result.nextCursor, equals('cursor_2'));
      expect(result.hasMore, isTrue);
    });

    test('returns null for expired cache', () async {
      final response = _createSampleResponse();
      const cacheKey = 'feed_expired';

      // Insert with a cached_at timestamp far in the past (TTL = 300000ms = 5 min)
      final expiredTimestamp =
          DateTime.now().millisecondsSinceEpoch - 400000; // 6+ min ago
      await db.insert('article_cache', {
        'cache_key': cacheKey,
        'response_json':
            '{"items":[{"id":"a1","title":"Test Article","summary":"Summary","content":null,"image_url":null,"category":"tech","comment_count":5,"published_at":"2025-01-01T00:00:00Z","source_name":"TestSource"}],"next_cursor":"cursor_2","has_more":true}',
        'cached_at': expiredTimestamp,
        'ttl_ms': 300000,
      });

      final result = await dataSource.getCachedFeed(cacheKey);
      expect(result, isNull);
    });

    test('clears expired entries', () async {
      // Insert an expired entry directly
      final expiredTimestamp =
          DateTime.now().millisecondsSinceEpoch - 400000;
      await db.insert('article_cache', {
        'cache_key': 'expired_key',
        'response_json': '{"items":[],"next_cursor":null,"has_more":false}',
        'cached_at': expiredTimestamp,
        'ttl_ms': 300000,
      });

      // Insert a valid entry
      final validResponse = _createSampleResponse();
      await dataSource.cacheFeed('valid_key', validResponse);

      // Clear expired
      await dataSource.clearExpiredCache();

      // Expired entry should be gone
      final rows = await db.query(
        'article_cache',
        where: 'cache_key = ?',
        whereArgs: ['expired_key'],
      );
      expect(rows, isEmpty);

      // Valid entry should remain
      final validResult = await dataSource.getCachedFeed('valid_key');
      expect(validResult, isNotNull);
    });

    test('overwrites existing cache with same key', () async {
      const cacheKey = 'feed_overwrite';

      final response1 = _createSampleResponse(
        articleId: 'a1',
        title: 'First',
      );
      final response2 = _createSampleResponse(
        articleId: 'a2',
        title: 'Second',
      );

      await dataSource.cacheFeed(cacheKey, response1);
      await dataSource.cacheFeed(cacheKey, response2);

      final result = await dataSource.getCachedFeed(cacheKey);
      expect(result, isNotNull);
      expect(result!.items.first.id, equals('a2'));
      expect(result.items.first.title, equals('Second'));

      // Should have only 1 row for that key
      final rows = await db.query(
        'article_cache',
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
      );
      expect(rows.length, equals(1));
    });
  });
}
