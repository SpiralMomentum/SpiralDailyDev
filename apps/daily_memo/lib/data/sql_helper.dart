// import 'package:apps.daily_memo/data/model/memo/add_memo_model.dart';
// import 'package:apps.daily_memo/data/model/memo/saved_memo_model.dart';
// import 'package:flutter/foundation.dart';
// import 'package:path/path.dart';
// import 'package:sqflite/sqflite.dart';
//
// class SQLHelper {
//   static Future<Database> db() async {
//     return openDatabase(
//       join(await getDatabasesPath(), 'memo.db'),
//       version: 1,
//       onCreate: (Database database, int version) async {
//         await _createTables(database);
//       },
//     );
//   }
//
//   // id: the id of a item
//   // title, description: name and description of your activity
//   // created_at: the time that the item was created. It will be automatically handled by SQLite
//
//   static Future<void> _createTables(Database database) async {
//     await database.execute(
//         "CREATE TABLE memos(memoId INTEGER PRIMARY KEY autoincrement, title TEXT, author TEXT, content TEXT, madeDateTime TEXT, modifiedDateTime TEXT)");
//   }
//
//   // Create new item (journal)
//   static Future<int> createItem(AddMemoModel memo) async {
//     final db = await SQLHelper.db();
//
//     final int insertResult = await db.insert(
//       'memos',
//       memo.toJson(),
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//
//     return insertResult;
//   }
//
//   // Read all items (journals)
//   static Future<List<SavedMemoModel>> getItems() async {
//     final db = await SQLHelper.db();
//     return (await db.query('memos', orderBy: "memoId"))
//         .map(SavedMemoModel.fromJson)
//         .toList();
//   }
//
//   // Read a single item by id
//   // The app doesn't use this method but I put here in case you want to see it
//   static Future<SavedMemoModel> getItem(int memoId) async {
//     final db = await SQLHelper.db();
//     return (await db.query('memos', orderBy: "memoId"))
//         .where((e) => e["memoId"] == memoId)
//         .map(SavedMemoModel.fromJson)
//         .first;
//   }
//
//   // Update an item by id
//   static Future<int> updateItem(SavedMemoModel memo) async {
//     final db = await SQLHelper.db();
//
//     final result = await db.update(
//       'memos',
//       memo.toJson(),
//       where: "memoId = ?",
//       whereArgs: [memo.memoId],
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//
//     return result;
//   }
//
//   // Delete
//   static Future<bool> deleteItem(int dbId) async {
//     final db = await SQLHelper.db();
//     try {
//       await db.delete("memos", where: "memoId = ?", whereArgs: [dbId]);
//       return true;
//     } catch (err) {
//       debugPrint("Something went wrong when deleting an item: $err");
//       return false;
//     }
//   }
// }

import 'package:apps.daily_memo/data/model/memo/saved_memo_model.dart';
import 'package:flutter/foundation.dart';
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
