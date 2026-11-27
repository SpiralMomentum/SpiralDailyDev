import '../../budget/domain/budget_alert.dart';
import '../../budget/domain/period.dart';
import '../../budget/domain/summary.dart';
import '../../ledger/data/sql_ledger_repository.dart' show LedgerRepository;
import '../../ledger/domain/decide.dart';
import '../../ledger/domain/transaction.dart';
import '../../message_filter/domain/filter.dart';
import '../../message_filter/domain/raw_message.dart';
import '../../parsing/data/sql_format_hint_repository.dart'
    show FormatHintRepository;
import '../../parsing/domain/format_hint.dart';
import '../../parsing/domain/parser.dart';
import '../../parsing/domain/signature.dart';
import '../../settings/data/sql_settings_repository.dart'
    show SettingsRepository;
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
  await d.ledger.upsertAll([decision.incoming, ...decision.updated]);
  if (decision.notify) await d.notifier.askConfirm(decision.incoming);
  for (final id in _withdrawnPending(recent, decision.updated)) {
    await d.notifier.cancel(id);
  }
  await refreshOutputs(d);
  return (IngestResult.stored, decision.incoming);
}

/// 확인 대기였다가 이번 결정으로 취소된 거래 id. 그 확인 알림은 거둬야 한다.
Iterable<String> _withdrawnPending(
  List<Transaction> before,
  List<Transaction> updated,
) {
  final pendingIds = {
    for (final t in before)
      if (t.status == TxStatus.pending) t.id,
  };
  return updated
      .where((t) => t.status == TxStatus.cancelled && pendingIds.contains(t.id))
      .map((t) => t.id);
}

/// 확인 대기 거래를 포함/제외로 확정한다. 대기 상태가 아니면 아무것도 하지 않는다.
Future<void> resolveCandidate(String id, bool include, IngestDeps d) async {
  final current = await d.ledger.byId(id);
  if (current == null || current.status != TxStatus.pending) return;
  final settings = await d.settings.load();
  final resolved = current.copyWith(
    status: include ? TxStatus.included : TxStatus.excluded,
    clearRawText: settings.deleteRawText,
  );
  await d.ledger.upsertAll([resolved]);
  await d.notifier.cancel(id);
  await refreshOutputs(d);
}

/// 사용자가 고친 거래를 저장한다. 원문이 남아 있으면 그 형식을 학습한다.
Future<void> saveEdit(Transaction edited, IngestDeps d) async {
  final stored = await d.ledger.byId(edited.id);
  final rawText = stored?.rawText;
  if (rawText != null) {
    final hint = learnHint(
      rawText,
      stored!.sender,
      amount: edited.amount.abs(),
      counterparty: edited.counterparty,
    );
    if (hint != null) await d.hints.put(hint);
  }
  await d.ledger.upsertAll([edited]);
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
  if (alert != null) {
    await d.notifier.budgetAlert(alert, summary);
    await d.settings.markSent(period.key, alert);
  }
  return summary;
}
