import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/budget/domain/budget_alert.dart';
import 'package:spend_ledger/features/ingest/domain/ingest.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';
import 'package:spend_ledger/features/settings/domain/app_settings.dart';

import '../../fixtures/messages.dart';
import '../../support/fakes.dart';

void main() {
  late IngestHarness h;
  tearDown(() => h.close());

  Future<void> open([AppSettings settings = const AppSettings()]) async {
    h = await openHarness(settings: settings);
  }

  test('deposit filtered not stored', () async {
    await open();

    final (result, tx) = await h.ingest(deposit);

    expect(result, IngestResult.filtered);
    expect(tx, isNull);
    expect(await h.deps.ledger.since(DateTime(2000)), isEmpty);
    expect(h.notifier.asked, isEmpty);
    expect(h.widgets.last, isNull);
  });

  test('no amount stored as needs review without notify', () async {
    await open();

    final (result, tx) = await h.ingest(noAmount);

    expect(result, IngestResult.stored);
    final stored = await h.deps.ledger.byId(tx!.id);
    expect(stored!.needsReview, isTrue);
    expect(stored.status, TxStatus.pending);
    expect(h.notifier.asked, isEmpty);
    expect(h.widgets.last!['pending'], '1');
  });

  test('resolve ignores cancelled', () async {
    await open();
    final (_, approval) = await h.ingest(kbApproval);
    await resolveCandidate(approval!.id, true, h.deps);
    await h.ingest(kbCancel);

    await resolveCandidate(approval.id, true, h.deps);

    expect((await h.deps.ledger.byId(approval.id))!.status, TxStatus.cancelled);
  });

  test('resolve deletes raw text when enabled', () async {
    await open();
    final (_, tx) = await h.ingest(kbApproval);
    expect((await h.deps.ledger.byId(tx!.id))!.rawText, kbApproval);

    await resolveCandidate(tx.id, false, h.deps);

    final stored = await h.deps.ledger.byId(tx.id);
    expect(stored!.status, TxStatus.excluded);
    expect(stored.rawText, isNull);
    expect(h.notifier.cancelled, [tx.id]);
  });

  test('resolve keeps raw text when disabled', () async {
    await open(const AppSettings(deleteRawText: false));
    final (_, tx) = await h.ingest(kbApproval);

    await resolveCandidate(tx!.id, true, h.deps);

    final stored = await h.deps.ledger.byId(tx.id);
    expect(stored!.status, TxStatus.included);
    expect(stored.rawText, kbApproval);
  });

  test('cancel of pending original withdraws its notification', () async {
    await open();
    final (_, approval) = await h.ingest(kbApproval);

    await h.ingest(kbCancel);

    expect(h.notifier.cancelled, [approval!.id]);
  });

  test('edit learns hint', () async {
    await open();
    final (_, tx) = await h.ingest(noKeyword);
    expect(await h.deps.hints.get(tx!.signature), isNull);

    await saveEdit(
      tx.copyWith(counterparty: '배달의민족', status: TxStatus.included),
      h.deps,
    );

    final hint = await h.deps.hints.get(tx.signature);
    expect(hint, isNotNull);
    expect(hint!.amountOrdinal, 0);
    expect((await h.deps.ledger.byId(tx.id))!.status, TxStatus.included);
    expect(h.widgets.last!['total'], '8,900원');
  });

  test('budget alert sent once', () async {
    await open(const AppSettings(budget: 7000));
    final (_, tx) = await h.ingest(kbApproval);
    expect(h.notifier.alerts, isEmpty);

    await resolveCandidate(tx!.id, true, h.deps);
    await refreshOutputs(h.deps);
    await h.ingest(noAmount);

    expect(h.notifier.alerts, [BudgetAlert.projectedOver]);
    expect(await h.deps.settings.sentAlerts('2026-11-01'), {
      BudgetAlert.projectedOver,
    });
  });
}
