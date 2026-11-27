import 'package:flutter/foundation.dart' show debugPrint;
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

/// 메인 isolate와 알림 백그라운드 isolate가 같은 파일을 동시에 연다.
/// 잠금 충돌 시 바로 실패하지 않고 최대 5초 기다리며, WAL로 읽기와 쓰기가 서로 막지 않게 한다.
/// PRAGMA는 결과 행을 돌려주므로 rawQuery로 실행한다.
/// WAL 전환이 실패해도(다른 isolate의 잠금, 네이티브 미지원 등) DB는 열려야 하므로 기록만 한다.
Future<void> configureLedgerDatabase(DatabaseExecutor db) async {
  await db.rawQuery('PRAGMA busy_timeout = 5000');
  try {
    await db.rawQuery('PRAGMA journal_mode = WAL');
  } catch (e) {
    debugPrint('journal_mode WAL failed: $e');
  }
}

/// 운영용 암호화 DB. 테스트에서는 사용하지 않는다(test/support/memory_db.dart).
Future<Database> openLedgerDatabase(String path, String key) =>
    cipher.openDatabase(
      path,
      password: key,
      version: 1,
      onConfigure: configureLedgerDatabase,
      onCreate: (db, _) => createLedgerSchema(db),
    );
