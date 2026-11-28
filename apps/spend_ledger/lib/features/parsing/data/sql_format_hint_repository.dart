import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';

import '../domain/format_hint.dart';
import '../domain/format_hint_repository.dart';

class SqlFormatHintRepository implements FormatHintRepository {
  const SqlFormatHintRepository(this._db);

  final Database _db;

  @override
  Future<FormatHint?> get(String signature) async {
    final rows = await _db.query(
      'format_hints',
      where: 'signature = ?',
      whereArgs: [signature],
    );
    if (rows.isEmpty) return null;
    return FormatHint.fromJson(
      jsonDecode(rows.first['json']! as String) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> put(FormatHint hint) => _db.insert('format_hints', {
    'signature': hint.signature,
    'json': jsonEncode(hint.toJson()),
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}
