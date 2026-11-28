import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/ledger/data/ledger_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('v1 database gains seen_notifications on upgrade', () async {
    sqfliteFfiInit();
    final dir = Directory.systemTemp.createTempSync('ledger_upgrade');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/ledger.db';

    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => createLedgerSchema(db, version: 1),
      ),
    );
    expect(
      await v1.rawQuery(
        "SELECT name FROM sqlite_master WHERE name='seen_notifications'",
      ),
      isEmpty,
    );
    await v1.close();

    final v2 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: ledgerSchemaVersion,
        onUpgrade: upgradeLedgerSchema,
      ),
    );
    expect(ledgerSchemaVersion, 2);
    expect(
      await v2.rawQuery(
        "SELECT name FROM sqlite_master WHERE name='seen_notifications'",
      ),
      hasLength(1),
    );
    await v2.close();
  });
}
