import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  test('WAL failure does not stop configuration', () async {
    final db = _Executor();
    final pragmas = <String>[];
    when(() => db.rawQuery(any())).thenAnswer((inv) async {
      final sql = inv.positionalArguments.first as String;
      pragmas.add(sql);
      if (sql.contains('journal_mode')) throw StateError('database is locked');
      return const [];
    });
    final logs = <String>[];
    debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
    addTearDown(() => debugPrint = debugPrintThrottled);

    await configureLedgerDatabase(db);

    expect(pragmas, [
      'PRAGMA busy_timeout = 5000',
      'PRAGMA journal_mode = WAL',
    ]);
    expect(logs.single, contains('database is locked'));
  });
}

class _Executor extends Mock implements DatabaseExecutor {}
