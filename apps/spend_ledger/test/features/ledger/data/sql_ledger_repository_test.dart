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

  test('resolvePending changes only pending rows', () async {
    await repo.upsertAll([tx('p'), tx('c', status: TxStatus.cancelled)]);

    expect(
      await repo.resolvePending('p', TxStatus.included, clearRawText: true),
      isTrue,
    );
    expect(
      await repo.resolvePending('c', TxStatus.included, clearRawText: true),
      isFalse,
    );
    expect(
      await repo.resolvePending('p', TxStatus.excluded, clearRawText: false),
      isFalse,
    );
    expect(
      await repo.resolvePending('zzz', TxStatus.included, clearRawText: true),
      isFalse,
    );

    final p = await repo.byId('p');
    expect(p!.status, TxStatus.included);
    expect(p.rawText, isNull);
    expect(await repo.byId('c'), tx('c', status: TxStatus.cancelled));
  });

  test('resolvePending keeps raw text when asked', () async {
    await repo.upsertAll([tx('p')]);
    await repo.resolvePending('p', TxStatus.excluded, clearRawText: false);
    final p = await repo.byId('p');
    expect(p!.status, TxStatus.excluded);
    expect(p.rawText, '원문');
  });

  test('updateEditable skips cancelled and duplicate', () async {
    await repo.upsertAll([
      tx('i', status: TxStatus.included),
      tx('c', status: TxStatus.cancelled),
      tx('d', status: TxStatus.duplicate),
    ]);
    Transaction edit(String id) => tx(id).copyWith(
      amount: 7000,
      counterparty: '카페',
      occurredAt: DateTime(2026, 11, 2),
      category: SpendCategory.spend,
      status: TxStatus.included,
    );

    expect(await repo.updateEditable(edit('i'), clearRawText: false), isTrue);
    expect(await repo.updateEditable(edit('c'), clearRawText: true), isFalse);
    expect(await repo.updateEditable(edit('d'), clearRawText: true), isFalse);

    expect(await repo.byId('i'), edit('i'));
    expect(await repo.byId('c'), tx('c', status: TxStatus.cancelled));
    expect(await repo.byId('d'), tx('d', status: TxStatus.duplicate));
  });

  test('updateEditable clears raw text when asked', () async {
    await repo.upsertAll([tx('p')]);
    final edited = tx('p').copyWith(status: TxStatus.excluded);

    expect(await repo.updateEditable(edited, clearRawText: true), isTrue);

    expect(await repo.byId('p'), edited.copyWith(clearRawText: true));
  });

  group('markCancelled', () {
    Transaction live(String id, TxStatus status, {SpendCategory? category}) =>
        tx(id, status: status).copyWith(
          category: category ?? SpendCategory.spend,
          needsReview: false,
        );

    test('cancels pending, included and live prepaidUse only', () async {
      await repo.upsertAll([
        live('p', TxStatus.pending),
        live('i', TxStatus.included),
        live('e', TxStatus.excluded),
        live('c', TxStatus.cancelled),
        live('d', TxStatus.duplicate),
        live('pe', TxStatus.excluded, category: SpendCategory.prepaidUse),
        live('pd', TxStatus.duplicate, category: SpendCategory.prepaidUse),
        live('pc', TxStatus.cancelled, category: SpendCategory.prepaidUse),
        live('u', TxStatus.included, category: SpendCategory.unknown),
        live('r', TxStatus.included).copyWith(needsReview: true),
      ]);

      final results = {
        for (final id in ['p', 'i', 'e', 'c', 'd', 'pe', 'pd', 'pc', 'u', 'r'])
          id: await repo.markCancelled(id, clearRawText: false),
      };

      expect(results, {
        'p': true,
        'i': true,
        'e': false,
        'c': false,
        'd': false,
        'pe': true,
        'pd': false,
        'pc': false,
        'u': false,
        'r': false,
      });
      expect((await repo.byId('p'))!.status, TxStatus.cancelled);
      expect((await repo.byId('p'))!.rawText, '원문');
      expect((await repo.byId('e'))!.status, TxStatus.excluded);
      expect(await repo.markCancelled('zzz', clearRawText: true), isFalse);
    });

    test('clears raw text when asked', () async {
      await repo.upsertAll([live('i', TxStatus.included)]);

      expect(await repo.markCancelled('i', clearRawText: true), isTrue);

      final i = await repo.byId('i');
      expect(i!.status, TxStatus.cancelled);
      expect(i.rawText, isNull);
    });
  });
}
