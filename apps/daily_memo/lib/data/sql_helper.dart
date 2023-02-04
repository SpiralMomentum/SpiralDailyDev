import 'package:apps.daily_memo/data/entity/memo_entiry.dart';
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
        "CREATE TABLE memos(id INTEGER PRIMARY KEY autoincrement, title TEXT, author TEXT, content TEXT, madeDateTime TEXT, modifiedDateTime TEXT)");
  }

  // Create new item (journal)
  static Future<MemoEntity> createItem(MemoEntity memo) async {
    final db = await SQLHelper.db();

    final int id = await db.insert(
      'memos',
      memo.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    memo.copyWith(id: id);

    return memo;
  }

  // Read all items (journals)
  static Future<List<MemoEntity>> getItems() async {
    final db = await SQLHelper.db();
    return (await db.query('memos', orderBy: "id"))
        .map(MemoEntity.fromJson)
        .toList();
  }

  // Read a single item by id
  // The app doesn't use this method but I put here in case you want to see it
  static Future<MemoEntity> getItem(int id) async {
    final db = await SQLHelper.db();
    return (await db.query('memos', orderBy: "id"))
        .where((e) => e["id"] == id)
        .map(MemoEntity.fromJson)
        .first;
  }

  // Update an item by id
  static Future<int> updateItem(int dbId, MemoEntity memo) async {
    final db = await SQLHelper.db();

    final result = await db
        .update('items', memo.toJson(), where: "id = ?", whereArgs: [dbId]);
    return result;
  }

  // Delete
  static Future<void> deleteItem(int dbId) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("memos", where: "id = ?", whereArgs: [dbId]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }
}
