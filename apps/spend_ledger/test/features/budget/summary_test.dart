import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/budget/domain/summary.dart';
import 'package:spend_ledger/features/ledger/domain/money_format.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';
import 'package:spend_ledger/features/parsing/domain/parsed_message.dart';

Transaction tx(
  String id,
  int amount,
  DateTime at, {
  String name = '가게',
  TxStatus status = TxStatus.included,
}) => Transaction(
  id: id,
  amount: amount,
  counterparty: name,
  occurredAt: at,
  receivedAt: at,
  kind: MessageKind.approval,
  category: SpendCategory.spend,
  status: status,
  needsReview: false,
  signature: id,
);

void main() {
  final now = DateTime(2026, 11, 27, 12);

  test('summary counts only included in period', () {
    final s = summarize(
      txs: [
        tx('a', 1000, DateTime(2026, 11, 5)),
        tx('b', 2000, DateTime(2026, 11, 27, 9)),
        tx('c', 5000, DateTime(2026, 10, 31)),
        tx('d', 7000, DateTime(2026, 11, 6), status: TxStatus.excluded),
        tx('e', 9000, DateTime(2026, 12, 1)),
        tx('f', -500, DateTime(2026, 11, 8)),
      ],
      now: now,
      startDay: 1,
    );
    expect(s.periodTotal, 2500);
    expect(s.todayTotal, 2000);
    expect(s.elapsedDays, 27);
    expect(s.budget, isNull);
    expect(s.budgetRatio, isNull);
    expect(s.dailyAllowance, isNull);
    expect(s.recent.map((t) => t.id), ['b', 'f', 'a']);
  });

  test('daily allowance', () {
    final s = summarize(
      txs: [tx('a', 120000, DateTime(2026, 11, 3))],
      now: now,
      startDay: 1,
      budget: 300000,
    );
    expect(s.period.totalDays, 30);
    expect(s.dailyAllowance, 45000);
    expect(s.budgetRatio, 0.4);
  });

  test('daily allowance floors at zero when over budget', () {
    final s = summarize(
      txs: [tx('a', 400000, DateTime(2026, 11, 3))],
      now: now,
      startDay: 1,
      budget: 300000,
    );
    expect(s.dailyAllowance, 0);
  });

  test('zero budget gives null ratio', () {
    final s = summarize(txs: const [], now: now, startDay: 1, budget: 0);
    expect(s.budgetRatio, isNull);
  });

  test('top merchants sorted', () {
    final s = summarize(
      txs: [
        tx('1', 3000, DateTime(2026, 11, 2), name: 'A'),
        tx('2', 5000, DateTime(2026, 11, 3), name: 'B'),
        tx('3', 4000, DateTime(2026, 11, 4), name: 'A'),
        tx('4', 1000, DateTime(2026, 11, 5), name: 'C'),
        tx('5', 2000, DateTime(2026, 11, 6), name: 'D'),
        tx('6', -9000, DateTime(2026, 11, 7), name: 'E'),
      ],
      now: now,
      startDay: 1,
    );
    expect(s.topMerchants.map((m) => m.name), ['A', 'B', 'D']);
    expect(s.topMerchants.first.amount, 7000);
  });

  test('pending count', () {
    final s = summarize(
      txs: [
        tx('1', 1000, DateTime(2026, 11, 2), status: TxStatus.pending),
        tx('2', 1000, DateTime(2026, 9, 2), status: TxStatus.pending),
        tx('3', 1000, DateTime(2026, 11, 2)),
      ],
      now: now,
      startDay: 1,
    );
    expect(s.pendingCount, 2);
    expect(s.periodTotal, 1000);
  });

  test('formatWon', () {
    expect(formatWon(6500), '6,500원');
    expect(formatWon(-6500), '-6,500원');
    expect(formatWon(0), '0원');
    expect(formatWon(1234567), '1,234,567원');
  });
}
