import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/budget/domain/budget_alert.dart';
import 'package:spend_ledger/features/ingest/domain/ingest.dart';
import 'package:spend_ledger/features/ledger/domain/ledger_repository.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';
import 'package:spend_ledger/features/message_filter/domain/name_registry.dart';
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

  group('raw text deletion on ingest', () {
    const prepaid = AppSettings(
      names: NameRegistry(
        selfNames: [],
        chargeTargets: [],
        prepaidMoneys: ['쿠페이머니'],
      ),
    );
    Future<String?> rawOf(String id) async =>
        (await h.deps.ledger.byId(id))!.rawText;

    test('auto-excluded incoming is stored without raw text', () async {
      await open(prepaid);
      final (_, tx) = await h.ingest(coupayMoneyPayment);
      expect(tx!.status, TxStatus.excluded);
      expect(await rawOf(tx.id), isNull);
    });

    test('duplicate incoming is stored without raw text', () async {
      await open();
      final (_, first) = await h.ingest(kbApproval);
      final (_, second) = await h.ingest(kbApproval);
      expect(second!.status, TxStatus.duplicate);
      expect(await rawOf(second.id), isNull);
      expect(await rawOf(first!.id), kbApproval);
    });

    test('cancel clears raw text of refund and cancelled original', () async {
      await open();
      final (_, approval) = await h.ingest(kbApproval);
      final (_, cancel) = await h.ingest(kbCancel);
      expect(cancel!.status, TxStatus.excluded);
      expect(cancel.linkedId, approval!.id);
      final original = await h.deps.ledger.byId(approval.id);
      expect(original!.status, TxStatus.cancelled);
      expect(original.rawText, isNull);
      expect(await rawOf(cancel.id), isNull);
    });

    test('prepaid-money cancel without original has no raw text', () async {
      await open(prepaid);
      final (_, tx) = await h.ingest(
        '[쿠팡] 쿠페이머니 결제 취소 30,000원\n11/27 19:00 쿠팡',
      );
      expect(tx!.status, TxStatus.excluded);
      expect(await rawOf(tx.id), isNull);
    });

    test('pending incoming keeps raw text', () async {
      await open();
      final (_, tx) = await h.ingest(kbApproval);
      expect(await rawOf(tx!.id), kbApproval);
    });

    test('raw text kept everywhere when deletion is off', () async {
      await open(prepaid.copyWith(deleteRawText: false));
      final (_, approval) = await h.ingest(kbApproval);
      final (_, cancel) = await h.ingest(kbCancel);
      final (_, use) = await h.ingest(coupayMoneyPayment);
      expect(use!.status, TxStatus.excluded);
      expect(await rawOf(approval!.id), kbApproval);
      expect(await rawOf(cancel!.id), kbCancel);
      expect(await rawOf(use.id), coupayMoneyPayment);
    });

    test('cancel does not overwrite an original resolved meanwhile', () async {
      await open();
      final (_, approval) = await h.ingest(kbApproval);
      // 취소 문자가 읽은 뒤 사용자가 제외로 확정한 상황: 저장 직전 상태를 바꾼다.
      final racing = _ResolveBeforeCancel(h.deps.ledger, approval!.id);
      final deps = IngestDeps(
        ledger: racing,
        settings: h.deps.settings,
        hints: h.deps.hints,
        notifier: h.deps.notifier,
        widgets: h.deps.widgets,
        now: h.deps.now,
        newId: h.deps.newId,
      );

      await ingestMessage(h.receive(kbCancel), deps);

      final original = await h.deps.ledger.byId(approval.id);
      expect(original!.status, TxStatus.excluded);
      expect(h.notifier.cancelled, isNot(contains(approval.id)));
    });
  });

  test('edit to included or excluded clears raw text after learning', () async {
    await open();
    final (_, tx) = await h.ingest(noKeyword);

    await saveEdit(
      tx!.copyWith(counterparty: '배달의민족', status: TxStatus.excluded),
      h.deps,
    );

    expect(await h.deps.hints.get(tx.signature), isNotNull);
    expect((await h.deps.ledger.byId(tx.id))!.rawText, isNull);
  });

  test('edit that stays pending keeps raw text', () async {
    await open();
    final (_, tx) = await h.ingest(noKeyword);

    await saveEdit(tx!.copyWith(counterparty: '배달의민족'), h.deps);

    expect((await h.deps.ledger.byId(tx.id))!.rawText, noKeyword);
  });

  test('edit keeps raw text when deletion is off', () async {
    await open(const AppSettings(deleteRawText: false));
    final (_, tx) = await h.ingest(noKeyword);

    await saveEdit(tx!.copyWith(status: TxStatus.included), h.deps);

    expect((await h.deps.ledger.byId(tx.id))!.rawText, noKeyword);
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

  test('resolve after cancel keeps cancelled', () async {
    await open();
    final (_, approval) = await h.ingest(kbApproval);
    await h.ingest(kbCancel);
    final cancelsBefore = List.of(h.notifier.cancelled);
    h.widgets.last = null;

    await resolveCandidate(approval!.id, true, h.deps);

    expect((await h.deps.ledger.byId(approval.id))!.status, TxStatus.cancelled);
    expect(h.notifier.cancelled, cancelsBefore);
    expect(h.widgets.last, isNull);
    expect(await refreshOutputs(h.deps).then((s) => s.periodTotal), 0);
  });

  test('double resolve: second is no-op', () async {
    await open();
    final (_, tx) = await h.ingest(kbApproval);

    await resolveCandidate(tx!.id, true, h.deps);
    await resolveCandidate(tx.id, false, h.deps);

    expect((await h.deps.ledger.byId(tx.id))!.status, TxStatus.included);
    expect(h.notifier.cancelled, [tx.id]);
  });

  test('edit does not resurrect cancelled', () async {
    await open();
    final (_, approval) = await h.ingest(kbApproval);
    await h.ingest(kbCancel);

    await saveEdit(approval!.copyWith(status: TxStatus.included), h.deps);

    expect((await h.deps.ledger.byId(approval.id))!.status, TxStatus.cancelled);
    expect(await refreshOutputs(h.deps).then((s) => s.periodTotal), 0);
  });

  test('notifier failure on ingest still refreshes widgets', () async {
    await open();
    h.notifier.failing = true;

    await expectLater(h.ingest(kbApproval), throwsStateError);

    expect(h.widgets.last!['pending'], '1');
    expect(await h.deps.ledger.byStatus({TxStatus.pending}), hasLength(1));
  });

  test('notifier failure on resolve still refreshes widgets', () async {
    await open();
    final (_, tx) = await h.ingest(kbApproval);
    h.notifier.failing = true;
    h.widgets.last = null;

    await expectLater(resolveCandidate(tx!.id, true, h.deps), throwsStateError);

    expect(h.widgets.last!['total'], '6,500원');
    expect(h.widgets.last!['pending'], '0');
  });
}

/// 취소 반영 직전에 원거래를 제외로 확정해, 수집과 사용자 확정이 겹친 상황을 만든다.
class _ResolveBeforeCancel implements LedgerRepository {
  _ResolveBeforeCancel(this._inner, this._id);

  final LedgerRepository _inner;
  final String _id;

  @override
  Future<Set<String>> saveIncoming(
    Transaction incoming,
    List<String> cancelIds, {
    required bool clearRawText,
  }) async {
    if (cancelIds.contains(_id)) {
      await _inner.resolvePending(_id, TxStatus.excluded, clearRawText: false);
    }
    return _inner.saveIncoming(incoming, cancelIds, clearRawText: clearRawText);
  }

  @override
  Future<void> upsertAll(List<Transaction> txs) => _inner.upsertAll(txs);

  @override
  Future<Transaction?> byId(String id) => _inner.byId(id);

  @override
  Future<List<Transaction>> since(DateTime from) => _inner.since(from);

  @override
  Future<List<Transaction>> byStatus(Set<TxStatus> statuses) =>
      _inner.byStatus(statuses);

  @override
  Future<bool> resolvePending(
    String id,
    TxStatus status, {
    required bool clearRawText,
  }) => _inner.resolvePending(id, status, clearRawText: clearRawText);

  @override
  Future<bool> updateEditable(
    Transaction edited, {
    required bool clearRawText,
  }) => _inner.updateEditable(edited, clearRawText: clearRawText);
}
