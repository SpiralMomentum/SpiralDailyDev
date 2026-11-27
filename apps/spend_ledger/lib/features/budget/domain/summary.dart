import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../ledger/domain/transaction.dart';
import 'period.dart';

class MerchantTotal extends Equatable {
  const MerchantTotal({required this.name, required this.amount});

  final String name;
  final int amount;

  @override
  List<Object?> get props => [name, amount];
}

class LedgerSummary extends Equatable {
  const LedgerSummary({
    required this.period,
    required this.periodTotal,
    required this.todayTotal,
    required this.budget,
    required this.budgetRatio,
    required this.dailyAllowance,
    required this.elapsedDays,
    required this.elapsedRatio,
    required this.topMerchants,
    required this.recent,
    required this.pendingCount,
  });

  final BudgetPeriod period;
  final int periodTotal;
  final int todayTotal;
  final int? budget;
  final double? budgetRatio;
  final int? dailyAllowance;
  final int elapsedDays;
  final double elapsedRatio;
  final List<MerchantTotal> topMerchants;
  final List<Transaction> recent;
  final int pendingCount;

  @override
  List<Object?> get props => [
    period,
    periodTotal,
    todayTotal,
    budget,
    budgetRatio,
    dailyAllowance,
    elapsedDays,
    elapsedRatio,
    topMerchants,
    recent,
    pendingCount,
  ];
}

LedgerSummary summarize({
  required List<Transaction> txs,
  required DateTime now,
  required int startDay,
  int? budget,
}) {
  final period = periodFor(now, startDay);
  final inPeriod = txs
      .where(
        (t) => t.status == TxStatus.included && period.contains(t.occurredAt),
      )
      .toList();

  final periodTotal = inPeriod.fold<int>(0, (a, t) => a + t.amount);
  final todayTotal = inPeriod
      .where(
        (t) =>
            t.occurredAt.year == now.year &&
            t.occurredAt.month == now.month &&
            t.occurredAt.day == now.day,
      )
      .fold<int>(0, (a, t) => a + t.amount);

  final totalDays = period.totalDays;
  final elapsedDays = daysBetween(period.start, now) + 1;

  final hasBudget = budget != null;
  final double? ratio = hasBudget && budget > 0 ? periodTotal / budget : null;
  final int? daily = hasBudget
      ? max(0, budget - periodTotal) ~/ (totalDays - elapsedDays + 1)
      : null;

  final sums = <String, int>{};
  for (final t in inPeriod) {
    sums.update(t.counterparty, (v) => v + t.amount, ifAbsent: () => t.amount);
  }
  final top =
      (sums.entries.where((e) => e.value > 0).toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(3)
          .map((e) => MerchantTotal(name: e.key, amount: e.value))
          .toList();

  final recent = (List<Transaction>.of(
    inPeriod,
  )..sort((a, b) => b.occurredAt.compareTo(a.occurredAt))).take(3).toList();

  return LedgerSummary(
    period: period,
    periodTotal: periodTotal,
    todayTotal: todayTotal,
    budget: budget,
    budgetRatio: ratio,
    dailyAllowance: daily,
    elapsedDays: elapsedDays,
    elapsedRatio: elapsedDays / totalDays,
    topMerchants: top,
    recent: recent,
    pendingCount: txs.where((t) => t.status == TxStatus.pending).length,
  );
}
