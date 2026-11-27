import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as cipher;

Future<void> createLedgerSchema(Database db) async {
  await db.execute('''
CREATE TABLE transactions(
  id TEXT PRIMARY KEY,
  amount INTEGER NOT NULL,
  counterparty TEXT NOT NULL,
  occurredAt INTEGER NOT NULL,
  receivedAt INTEGER NOT NULL,
  kind TEXT NOT NULL,
  category TEXT NOT NULL,
  status TEXT NOT NULL,
  linkedId TEXT,
  rawText TEXT,
  sender TEXT,
  needsReview INTEGER NOT NULL,
  signature TEXT NOT NULL
)''');
  await db.execute(
    'CREATE INDEX idx_transactions_occurredAt ON transactions(occurredAt)',
  );
  await db.execute(
    'CREATE INDEX idx_transactions_status ON transactions(status)',
  );
  await db.execute(
    'CREATE TABLE format_hints(signature TEXT PRIMARY KEY, json TEXT NOT NULL)',
  );
  await db.execute(
    'CREATE TABLE kv(key TEXT PRIMARY KEY, value TEXT NOT NULL)',
  );
}

/// 운영용 암호화 DB. 테스트에서는 사용하지 않는다(test/support/memory_db.dart).
Future<Database> openLedgerDatabase(String path, String key) =>
    cipher.openDatabase(
      path,
      password: key,
      version: 1,
      onCreate: (db, _) => createLedgerSchema(db),
    );
