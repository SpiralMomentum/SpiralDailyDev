import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

abstract class DatabaseHelper {
  Future<Database> openDB(String? dbName);

  Future<Iterable<dynamic>> getAllItems();

  Future<Iterable<dynamic>?> getItem(dynamic uniqueId);

  Future<void> createItem(dynamic model);

  Future<void> updateItem(dynamic uniqueId, dynamic model);

  Future<bool> removeItem(dynamic uniqueId);
}

class SQLHelper extends DatabaseHelper {
  final String _dbName = 'memo.db' '';

  @override
  Future<Database> openDB(String? dbName) async {
    return openDatabase(
      join(await getDatabasesPath(), dbName),
      version: 1,
      onCreate: (Database database, int version) async {
        await _createTables(database);
      },
    );
  }

  Future<void> _createTables(Database database) async {
    await database.execute(
        "CREATE TABLE memos(memoId INTEGER PRIMARY KEY autoincrement, title TEXT, author TEXT, content TEXT, madeDateTime TEXT, modifiedDateTime TEXT)");
  }

  @override
  Future<Iterable<dynamic>> getAllItems() async {
    final db = await openDB(_dbName);
    return (await db.query('memos', orderBy: "memoId"));
  }

  @override
  Future<Iterable<dynamic>?> getItem(uniqueId) async {
    final db = await openDB(_dbName);
    final result = (await db.query('memos', orderBy: "memoId"))
        .where((e) => e["memoId"] == uniqueId);
    if (result.isEmpty) return null;

    return result;
  }

  @override
  Future<void> createItem(model) async {
    final db = await openDB(_dbName);

    try {
      await db.insert(
        'memos',
        model.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException;
    }

    return;
  }

  @override
  Future<void> updateItem(uniqueId, model) async {
    final db = await openDB(_dbName);

    try {
      await db.update(
        'memos',
        model.toJson(),
        where: "memoId = ?",
        whereArgs: [uniqueId],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException;
    }
  }

  @override
  Future<bool> removeItem(uniqueId) async {
    final db = await openDB(_dbName);

    try {
      await db.delete("memos", where: "memoId = ?", whereArgs: [uniqueId]);
      return true;
    } catch (err) {
      return false;
    }
  }
}
