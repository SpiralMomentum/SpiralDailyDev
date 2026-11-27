import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;
import 'package:spend_ledger/features/ledger/data/ledger_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('configure sets busy timeout and WAL for shared access', () async {
    sqfliteFfiInit();
    final dir = await Directory.systemTemp.createTemp('ledger_db');
    final db = await databaseFactoryFfi.openDatabase(
      join(dir.path, 'ledger.db'),
      options: OpenDatabaseOptions(onConfigure: configureLedgerDatabase),
    );
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    final timeout = await db.rawQuery('PRAGMA busy_timeout');
    final mode = await db.rawQuery('PRAGMA journal_mode');

    expect(timeout.single.values.single, 5000);
    expect(mode.single.values.single, 'wal');
  });
}
