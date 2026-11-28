import 'package:spend_ledger/features/ledger/data/ledger_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> openMemoryDb() {
  sqfliteFfiInit();
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: ledgerSchemaVersion,
      onCreate: (db, _) => createLedgerSchema(db),
    ),
  );
}
