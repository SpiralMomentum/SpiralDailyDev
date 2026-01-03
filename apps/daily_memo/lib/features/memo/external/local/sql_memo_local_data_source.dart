import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:utils/utils.dart';

import 'package:apps.daily_memo/features/memo/data/datasources/memo_local_data_source.dart';
import 'package:apps.daily_memo/features/memo/data/exceptions/external_exception.dart';

class SqlMemoLocalDataSource implements MemoLocalDataSource {
  static const _dbName = 'memo.db';

  @override
  Future<Result<List<Map<String, Object?>>>> fetchAll() {
    return _guardQuery(() async {
      final db = await _openDB();
      return db.query('memos', orderBy: 'memoId');
    });
  }

  @override
  Future<Result<List<Map<String, Object?>>>> fetchById(int memoId) {
    return _guardQuery(() async {
      final db = await _openDB();
      return db.query('memos',
          orderBy: 'memoId', where: 'memoId = ?', whereArgs: [memoId]);
    });
  }

  @override
  Future<Result<void>> insert(Map<String, Object?> payload) {
    return _guardWrite(() async {
      final db = await _openDB();
      await db.insert(
        'memos',
        payload,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<Result<void>> update(int memoId, Map<String, Object?> payload) {
    return _guardWrite(() async {
      final db = await _openDB();
      await db.update(
        'memos',
        payload,
        where: 'memoId = ?',
        whereArgs: [memoId],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<Result<void>> delete(int memoId) {
    return _guardWrite(() async {
      final db = await _openDB();
      await db.delete('memos', where: 'memoId = ?', whereArgs: [memoId]);
    });
  }

  Future<Database> _openDB() async {
    return openDatabase(
      join(await getDatabasesPath(), _dbName),
      version: 1,
      onCreate: (Database database, int version) async {
        await _createTables(database);
      },
    );
  }

  Future<void> _createTables(Database database) async {
    await database.execute(
      'CREATE TABLE memos('
      'memoId INTEGER PRIMARY KEY autoincrement, '
      'title TEXT, '
      'author TEXT, '
      'content TEXT, '
      'madeDateTime TEXT, '
      'modifiedDateTime TEXT'
      ')',
    );
  }

  Future<Result<List<Map<String, Object?>>>> _guardQuery(
    Future<List<Map<String, Object?>>> Function() action,
  ) async {
    try {
      return Success(await action());
    } catch (error, stackTrace) {
      return ErrorResult(
        LocalStorageExternalException(
          message: '메모 저장소에 접근할 수 없습니다.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<Result<void>> _guardWrite(Future<void> Function() action) async {
    try {
      await action();
      return const Success(null);
    } catch (error, stackTrace) {
      return ErrorResult(
        LocalStorageExternalException(
          message: '메모 저장소에 접근할 수 없습니다.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
