import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/budget/domain/summary.dart';
import 'package:spend_ledger/features/ledger/domain/money_format.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';
import 'package:spend_ledger/features/parsing/domain/parsed_message.dart';
import 'package:spend_ledger/features/widget_sync/domain/widget_entries.dart';

Transaction tx(String id, int amount, DateTime at, String name) => Transaction(
  id: id,
  amount: amount,
  counterparty: name,
  occurredAt: at,
  receivedAt: at,
  kind: MessageKind.approval,
  category: SpendCategory.spend,
  status: TxStatus.included,
  needsReview: false,
  signature: id,
);

void main() {
  final now = DateTime(2026, 11, 27, 12);
  final txs = [
    tx('1', 6500, DateTime(2026, 11, 27, 9), '스타벅스'),
    tx('2', 120000 - 6500, DateTime(2026, 11, 3), '마트'),
  ];
  final summary = summarize(txs: txs, now: now, startDay: 1, budget: 300000);

  test('widget total equals summary total', () {
    final m = widgetEntries(summary, hideAmounts: false);
    expect(m['total'], formatWon(summary.periodTotal));
    expect(m['total'], '120,000원');
    expect(m['today'], '6,500원');
    expect(m['daily'], '45,000원');
    expect(m['ratio'], '40');
    expect(m['elapsed'], '90');
    expect(m['top1'], '마트 113,500원');
    expect(m['top2'], '스타벅스 6,500원');
    expect(m['top3'], '');
    expect(m['recent1'], '스타벅스 6,500원');
    expect(m['recent3'], '');
    expect(m['pending'], '0');
  });

  test('widget hides amounts keeps ratio', () {
    final m = widgetEntries(summary, hideAmounts: true);
    expect(m['total'], '');
    expect(m['today'], '');
    expect(m['daily'], '');
    expect(m['top1'], '마트');
    expect(m['recent1'], '스타벅스');
    expect(m['ratio'], '40');
    expect(m['elapsed'], '90');
    expect(m['pending'], '0');
  });

  test('ratio empty without budget', () {
    final m = widgetEntries(
      summarize(txs: txs, now: now, startDay: 1),
      hideAmounts: false,
    );
    expect(m['ratio'], '');
    expect(m['daily'], '');
  });
}
