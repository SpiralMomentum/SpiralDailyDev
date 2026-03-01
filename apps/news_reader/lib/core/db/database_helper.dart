import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static Database? _database;

  static const int _version = 1;
  static const String _dbName = 'news_reader.db';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bookmarks (
        article_id    TEXT PRIMARY KEY,
        title         TEXT NOT NULL,
        summary       TEXT NOT NULL DEFAULT '',
        content       TEXT NOT NULL DEFAULT '',
        image_url     TEXT NOT NULL DEFAULT '',
        category      TEXT NOT NULL DEFAULT 'general',
        saved_at      INTEGER NOT NULL,
        sync_status   TEXT NOT NULL DEFAULT 'synced',
        version       INTEGER NOT NULL DEFAULT 1,
        created_at    INTEGER NOT NULL,
        updated_at    INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE article_cache (
        cache_key     TEXT PRIMARY KEY,
        response_json TEXT NOT NULL,
        cached_at     INTEGER NOT NULL,
        ttl_ms        INTEGER NOT NULL DEFAULT 300000
      )
    ''');

    await db.execute('''
      CREATE TABLE search_history (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        query         TEXT NOT NULL UNIQUE,
        searched_at   INTEGER NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_bookmarks_saved_at ON bookmarks(saved_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_bookmarks_sync_status ON bookmarks(sync_status)',
    );
    await db.execute(
      'CREATE INDEX idx_article_cache_cached_at ON article_cache(cached_at)',
    );
    await db.execute(
      'CREATE INDEX idx_search_history_searched_at ON search_history(searched_at DESC)',
    );
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Future migrations go here
    // if (oldVersion < 2) { ... }
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
