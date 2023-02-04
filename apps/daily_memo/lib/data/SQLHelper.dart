import 'package:apps.daily_memo/data/entity/memo_entiry.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'memo.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await _createTables(database);
      },
    );
  }

  // id: the id of a item
  // title, description: name and description of your activity
  // created_at: the time that the item was created. It will be automatically handled by SQLite

  static Future<void> _createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE memos(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        title TEXT,
        description TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      """);
  }

  // Create new item (journal)
  static Future<int> createItem(MemoEntity memo) async {
    final db = await SQLHelper.db();

    final id = await db.insert(
      'memos',
      memo.toJson(),
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
    return id;
  }

  // Read all items (journals)
  static Future<List<Map<String, dynamic>>> getItems() async {
    final db = await SQLHelper.db();
    return db.query('memos', orderBy: "id");
  }

  // Read a single item by id
  // The app doesn't use this method but I put here in case you want to see it
  static Future<List<Map<String, dynamic>>> getItem(int id) async {
    final db = await SQLHelper.db();
    return db.query('memos', where: "id = ?", whereArgs: [id], limit: 1);
  }

  // Update an item by id
  static Future<int> updateItem(int dbId, MemoEntity memo) async {
    final db = await SQLHelper.db();

    final result =
    await db.update('items', memo.toJson(), where: "id = ?", whereArgs: [dbId]);
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
