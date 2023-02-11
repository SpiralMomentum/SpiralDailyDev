import 'package:apps.daily_memo/data/entity/add_memo_entity.dart';
import 'package:apps.daily_memo/data/entity/saved_memo_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SQLHelper {
  static Future<Database> db() async {
    return openDatabase(
      join(await getDatabasesPath(), 'memo.db'),
      version: 1,
      onCreate: (Database database, int version) async {
        await _createTables(database);
      },
    );
  }

  // id: the id of a item
  // title, description: name and description of your activity
  // created_at: the time that the item was created. It will be automatically handled by SQLite

  static Future<void> _createTables(Database database) async {
    await database.execute(
        "CREATE TABLE memos(memoId INTEGER PRIMARY KEY autoincrement, title TEXT, author TEXT, content TEXT, madeDateTime TEXT, modifiedDateTime TEXT)");
  }

  // Create new item (journal)
  static Future<int> createItem(AddMemoEntity memo) async {
    final db = await SQLHelper.db();

    final int insertResult = await db.insert(
      'memos',
      memo.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return insertResult;
  }

  // Read all items (journals)
  static Future<List<SavedMemoEntity>> getItems() async {
    final db = await SQLHelper.db();
    return (await db.query('memos', orderBy: "memoId"))
        .map(SavedMemoEntity.fromJson)
        .toList();
  }

  // Read a single item by id
  // The app doesn't use this method but I put here in case you want to see it
  static Future<SavedMemoEntity> getItem(int memoId) async {
    final db = await SQLHelper.db();
    return (await db.query('memos', orderBy: "memoId"))
        .where((e) => e["memoId"] == memoId)
        .map(SavedMemoEntity.fromJson)
        .first;
  }

  // Update an item by id
  static Future<int> updateItem(SavedMemoEntity memo) async {
    final db = await SQLHelper.db();

    final result = await db.update(
      'memos',
      memo.toJson(),
      where: "memoId = ?",
      whereArgs: [memo.memoId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return result;
  }

  // Delete
  static Future<bool> deleteItem(int dbId) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("memos", where: "memoId = ?", whereArgs: [dbId]);
      return true;
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
      return false;
    }
  }
}
