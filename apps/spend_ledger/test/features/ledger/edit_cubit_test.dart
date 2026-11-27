import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';
import 'package:spend_ledger/features/ledger/presentation/edit_cubit.dart';
import 'package:spend_ledger/features/parsing/domain/signature.dart';
import 'package:spend_ledger/features/settings/domain/app_settings.dart';

import '../../fixtures/messages.dart';
import '../../support/fakes.dart';

void main() {
  late IngestHarness h;
  tearDown(() => h.close());

  test('edit save includes and learns', () async {
    h = await openHarness(settings: const AppSettings(deleteRawText: false));
    final (_, tx) = await h.ingest(noKeyword);
    final cubit = EditCubit(h.deps, tx!);
    final when = DateTime(2026, 11, 27, 19, 40);

    await cubit.save(
      amount: 8900,
      counterparty: '배달의민족',
      occurredAt: when,
      category: SpendCategory.spend,
      include: true,
    );

    expect(cubit.state.saved, isTrue);
    final stored = await h.deps.ledger.byId(tx.id);
    expect(stored!.status, TxStatus.included);
    expect(stored.amount, 8900);
    expect(stored.counterparty, '배달의민족');
    expect(stored.occurredAt, when);
    final hint = await h.deps.hints.get(formatSignature(noKeyword, 'sender'));
    expect(hint, isNotNull);
    await cubit.close();
  });

  test('including a pending candidate withdraws its notification', () async {
    h = await openHarness();
    final (_, tx) = await h.ingest(kbApproval);
    final cubit = EditCubit(h.deps, tx!);

    await cubit.save(
      amount: 7000,
      counterparty: '스타벅스',
      occurredAt: tx.occurredAt,
      category: SpendCategory.spend,
      include: true,
    );

    final stored = await h.deps.ledger.byId(tx.id);
    expect(stored!.status, TxStatus.included);
    expect(stored.amount, 7000);
    expect(h.notifier.cancelled, [tx.id]);
    await cubit.close();
  });

  test('pending saved without include stays pending', () async {
    h = await openHarness();
    final (_, tx) = await h.ingest(noAmount);
    final cubit = EditCubit(h.deps, tx!);

    await cubit.save(
      amount: 5000,
      counterparty: '해외가맹점',
      occurredAt: tx.occurredAt,
      category: SpendCategory.spend,
      include: false,
    );

    final stored = await h.deps.ledger.byId(tx.id);
    expect(stored!.status, TxStatus.pending);
    expect(stored.amount, 5000);
    await cubit.close();
  });

  test('zero amount is not included', () async {
    h = await openHarness();
    final (_, tx) = await h.ingest(noAmount);
    final cubit = EditCubit(h.deps, tx!);

    await cubit.save(
      amount: 0,
      counterparty: '',
      occurredAt: tx.occurredAt,
      category: SpendCategory.spend,
      include: true,
    );

    expect((await h.deps.ledger.byId(tx.id))!.status, TxStatus.pending);
    await cubit.close();
  });

  test('unchecking an included transaction excludes it', () async {
    h = await openHarness();
    final (_, tx) = await h.ingest(kbApproval);
    final cubit = EditCubit(h.deps, tx!.copyWith(status: TxStatus.included));
    await h.deps.ledger.upsertAll([tx.copyWith(status: TxStatus.included)]);

    await cubit.save(
      amount: tx.amount,
      counterparty: tx.counterparty,
      occurredAt: tx.occurredAt,
      category: tx.category,
      include: false,
    );

    expect((await h.deps.ledger.byId(tx.id))!.status, TxStatus.excluded);
    await cubit.close();
  });
}
