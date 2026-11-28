import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/ingest/data/sql_seen_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../support/memory_db.dart';

void main() {
  late Database db;
  late SqlSeenRepository repo;
  final t0 = DateTime(2026, 11, 28, 10);
  const window = Duration(minutes: 10);

  setUp(() async {
    db = await openMemoryDb();
    repo = SqlSeenRepository(db);
  });
  tearDown(() => db.close());

  test('first claim true, within window false, after window true', () async {
    expect(await repo.claim('f', t0, window), isTrue);
    expect(
      await repo.claim('f', t0.add(const Duration(minutes: 9)), window),
      isFalse,
    );
    expect(
      await repo.claim('f', t0.add(const Duration(minutes: 11)), window),
      isTrue,
    );
  });

  test('different fingerprints are independent', () async {
    expect(await repo.claim('a', t0, window), isTrue);
    expect(await repo.claim('b', t0, window), isTrue);
  });

  test('release allows immediate reclaim', () async {
    await repo.claim('f', t0, window);
    await repo.release('f');
    expect(await repo.claim('f', t0, window), isTrue);
  });

  test('old records are pruned', () async {
    await repo.claim('old', t0, window);
    await repo.claim('new', t0.add(const Duration(minutes: 30)), window);
    final rows = await db.query('seen_notifications');
    expect(rows.map((r) => r['fingerprint']), ['new']);
  });
}
