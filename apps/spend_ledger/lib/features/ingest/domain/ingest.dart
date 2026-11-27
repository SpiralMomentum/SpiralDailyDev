import '../../budget/domain/budget_alert.dart';
import '../../budget/domain/period.dart';
import '../../budget/domain/summary.dart';
import '../../ledger/domain/decide.dart';
import '../../ledger/domain/ledger_repository.dart';
import '../../ledger/domain/transaction.dart';
import '../../message_filter/domain/filter.dart';
import '../../message_filter/domain/raw_message.dart';
import '../../parsing/domain/format_hint.dart';
import '../../parsing/domain/format_hint_repository.dart';
import '../../parsing/domain/parser.dart';
import '../../parsing/domain/signature.dart';
import '../../settings/domain/settings_repository.dart';
import '../../widget_sync/domain/widget_entries.dart';

abstract interface class ConfirmNotifier {
  Future<void> askConfirm(Transaction tx);
  Future<void> budgetAlert(BudgetAlert alert, LedgerSummary s);
  Future<void> cancel(String txId);
}

abstract interface class WidgetGateway {
  Future<void> save(Map<String, String> entries);
}

/// 위젯이 아직 없는 단계에서 쓰는 빈 구현.
class NoopWidgetGateway implements WidgetGateway {
  const NoopWidgetGateway();

  @override
  Future<void> save(Map<String, String> entries) async {}
}

class IngestDeps {
  const IngestDeps({
    required this.ledger,
    required this.settings,
    required this.hints,
    required this.notifier,
    required this.widgets,
    required this.now,
    required this.newId,
  });

  final LedgerRepository ledger;
  final SettingsRepository settings;
  final FormatHintRepository hints;
  final ConfirmNotifier notifier;
  final WidgetGateway widgets;
  final DateTime Function() now;
  final String Function() newId;
}

enum IngestResult { filtered, stored }

const Duration _recentWindow = Duration(days: 90);

/// 문자 한 통을 걸러 해석·분류하고 저장한다. 필터에 걸리면 아무것도 저장하지 않는다.
Future<(IngestResult, Transaction?)> ingestMessage(
  RawMessage raw,
  IngestDeps d,
) async {
  final settings = await d.settings.load();
  if (!passesFilter(raw, settings.filters)) {
    return (IngestResult.filtered, null);
  }
  final hint = await d.hints.get(formatSignature(raw.text, raw.sender));
  final parsed = parseMessage(
    raw.text,
    receivedAt: raw.receivedAt,
    sender: raw.sender,
    hint: hint,
  );
  final recent = await d.ledger.since(d.now().subtract(_recentWindow));
  final decision = decide(
    raw: raw,
    parsed: parsed,
    names: settings.names,
    recent: recent,
    newId: d.newId(),
  );
  final clearRaw = settings.deleteRawText;
  // 확인을 기다리지 않는 거래는 원문이 더 필요 없다.
  final incoming = clearRaw && decision.incoming.status != TxStatus.pending
      ? decision.incoming.copyWith(clearRawText: true)
      : decision.incoming;
  await d.ledger.upsertAll([incoming]);
  // 원거래는 읽어 둔 스냅샷으로 덮어쓰지 않고, 아직 취소 대상일 때만 조건부로 바꾼다.
  // 그 사이 사용자가 확정해 대상이 아니게 됐으면 그 결정을 남긴다(환불은 이미 제외로 저장됨).
  final cancelled = <String>{};
  for (final t in decision.updated) {
    if (await d.ledger.markCancelled(t.id, clearRawText: clearRaw)) {
      cancelled.add(t.id);
    }
  }
  await _notifyThenRefresh(d, () async {
    if (decision.notify) await d.notifier.askConfirm(incoming);
    for (final id in _withdrawnPending(recent, cancelled)) {
      await d.notifier.cancel(id);
    }
  });
  return (IngestResult.stored, incoming);
}

/// 알림 실패가 위젯·예산 갱신을 막지 않도록, 실패해도 갱신한 뒤 예외를 다시 던진다.
Future<void> _notifyThenRefresh(
  IngestDeps d,
  Future<void> Function() notify,
) async {
  try {
    await notify();
  } finally {
    await refreshOutputs(d);
  }
}

/// 확인 대기였다가 이번에 취소된 거래 id. 그 확인 알림은 거둬야 한다.
Iterable<String> _withdrawnPending(
  List<Transaction> before,
  Set<String> cancelled,
) => before
    .where((t) => t.status == TxStatus.pending && cancelled.contains(t.id))
    .map((t) => t.id);

/// 확인 대기 거래를 포함/제외로 확정한다. 대기 상태가 아니면 아무것도 하지 않는다.
/// 확인과 쓰기는 저장소의 한 문장으로 처리해 동시에 들어온 취소를 덮어쓰지 않는다.
Future<void> resolveCandidate(String id, bool include, IngestDeps d) async {
  final settings = await d.settings.load();
  final resolved = await d.ledger.resolvePending(
    id,
    include ? TxStatus.included : TxStatus.excluded,
    clearRawText: settings.deleteRawText,
  );
  if (!resolved) return;
  await _notifyThenRefresh(d, () => d.notifier.cancel(id));
}

/// 사용자가 고친 거래를 반영한다. 취소·중복 거래는 바꾸지 않는다.
/// 반영됐고 원문이 남아 있으면 그 형식을 학습한다. 원문 삭제 설정이면 포함/제외로
/// 확정된 거래의 원문은 같은 쓰기에서 지우고, 학습에는 미리 읽어 둔 원문을 쓴다.
Future<void> saveEdit(Transaction edited, IngestDeps d) async {
  final settings = await d.settings.load();
  final stored = await d.ledger.byId(edited.id);
  final clearRaw =
      settings.deleteRawText &&
      (edited.status == TxStatus.included ||
          edited.status == TxStatus.excluded);
  if (stored == null ||
      !await d.ledger.updateEditable(edited, clearRawText: clearRaw)) {
    return;
  }
  final rawText = stored.rawText;
  if (rawText != null) {
    final hint = learnHint(
      rawText,
      stored.sender,
      amount: edited.amount.abs(),
      counterparty: edited.counterparty,
    );
    if (hint != null) await d.hints.put(hint);
  }
  await refreshOutputs(d);
}

/// 요약을 다시 계산해 위젯을 갱신하고, 필요하면 예산 알림을 한 번 보낸다.
Future<LedgerSummary> refreshOutputs(IngestDeps d) async {
  final settings = await d.settings.load();
  final now = d.now();
  final period = periodFor(now, settings.startDay);
  final inPeriod = await d.ledger.since(period.start);
  final pending = await d.ledger.byStatus({TxStatus.pending});
  final txs = {
    for (final t in [...inPeriod, ...pending]) t.id: t,
  }.values.toList();
  final summary = summarize(
    txs: txs,
    now: now,
    startDay: settings.startDay,
    budget: settings.budget,
  );
  await d.widgets.save(
    widgetEntries(summary, hideAmounts: settings.hideAmounts),
  );
  final alert = nextBudgetAlert(
    summary,
    await d.settings.sentAlerts(period.key),
  );
  // 먼저 표시에 성공한 쪽만 보낸다. 동시에 갱신돼도 같은 알림은 한 번만 간다.
  if (alert != null && await d.settings.markSent(period.key, alert)) {
    await d.notifier.budgetAlert(alert, summary);
  }
  return summary;
}
