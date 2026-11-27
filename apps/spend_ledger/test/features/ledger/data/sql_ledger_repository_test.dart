import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/ledger/data/sql_ledger_repository.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';
import 'package:spend_ledger/features/parsing/data/sql_format_hint_repository.dart';
import 'package:spend_ledger/features/parsing/domain/format_hint.dart';
import 'package:spend_ledger/features/parsing/domain/parsed_message.dart';
import 'package:sqflite_common/sqlite_api.dart' hide Transaction;

import '../../../support/memory_db.dart';

Transaction tx(
  String id, {
  DateTime? at,
  TxStatus status = TxStatus.pending,
  int amount = -5000,
}) => Transaction(
  id: id,
  amount: amount,
  counterparty: '스타벅스',
  occurredAt: at ?? DateTime(2026, 11, 1, 12),
  receivedAt: DateTime(2026, 11, 1, 12, 1),
  kind: MessageKind.transfer,
  category: SpendCategory.refund,
  status: status,
  needsReview: true,
  signature: 'sig',
  linkedId: 'other',
  rawText: '원문',
  sender: '1588',
);

void main() {
  late Database db;
  late SqlLedgerRepository repo;
  setUp(() async {
    db = await openMemoryDb();
    repo = SqlLedgerRepository(db);
  });
  tearDown(() => db.close());

  test('upsert then byId roundtrip', () async {
    final t = tx('a');
    await repo.upsertAll([t]);
    expect(await repo.byId('a'), t);
    expect(await repo.byId('zzz'), isNull);
  });

  test('null fields roundtrip', () async {
    final t = tx('a').copyWith(clearLinkedId: true, clearRawText: true);
    final bare = Transaction(
      id: t.id,
      amount: t.amount,
      counterparty: t.counterparty,
      occurredAt: t.occurredAt,
      receivedAt: t.receivedAt,
      kind: t.kind,
      category: t.category,
      status: t.status,
      needsReview: false,
      signature: t.signature,
    );
    await repo.upsertAll([bare]);
    expect(await repo.byId('a'), bare);
  });

  test('upsert replaces same id', () async {
    await repo.upsertAll([tx('a')]);
    await repo.upsertAll([tx('a', amount: -9000)]);
    expect((await repo.byId('a'))!.amount, -9000);
    expect(await repo.since(DateTime(2000)), hasLength(1));
  });

  test('since filters by occurredAt ascending', () async {
    final early = tx('e', at: DateTime(2026, 10, 1));
    final mid = tx('m', at: DateTime(2026, 11, 1));
    final late = tx('l', at: DateTime(2026, 11, 5));
    await repo.upsertAll([late, early, mid]);
    expect(await repo.since(DateTime(2026, 11, 1)), [mid, late]);
  });

  test('byStatus filters, newest first', () async {
    final a = tx('a', at: DateTime(2026, 11, 1), status: TxStatus.included);
    final b = tx('b', at: DateTime(2026, 11, 2), status: TxStatus.pending);
    final c = tx('c', at: DateTime(2026, 11, 3), status: TxStatus.excluded);
    await repo.upsertAll([a, b, c]);
    expect(await repo.byStatus({TxStatus.included, TxStatus.pending}), [b, a]);
    expect(await repo.byStatus({}), isEmpty);
  });

  test('hint roundtrip', () async {
    final hints = SqlFormatHintRepository(db);
    const h = FormatHint(
      signature: 's1',
      amountOrdinal: 1,
      counterpartyLine: 2,
    );
    expect(await hints.get('s1'), isNull);
    await hints.put(h);
    expect(await hints.get('s1'), h);
    const h2 = FormatHint(signature: 's1', amountOrdinal: 0);
    await hints.put(h2);
    expect(await hints.get('s1'), h2);
  });
}
