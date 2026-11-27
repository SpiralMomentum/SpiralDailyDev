import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/budget/domain/budget_alert.dart';
import 'package:spend_ledger/features/budget/domain/period.dart';
import 'package:spend_ledger/features/budget/domain/summary.dart';

LedgerSummary s({required int total, int? budget, int elapsed = 10}) =>
    LedgerSummary(
      period: periodFor(DateTime(2026, 11, 10), 1),
      periodTotal: total,
      todayTotal: 0,
      budget: budget,
      budgetRatio: null,
      dailyAllowance: null,
      elapsedDays: elapsed,
      elapsedRatio: elapsed / 30,
      topMerchants: const [],
      recent: const [],
      pendingCount: 0,
    );

void main() {
  test('null budget gives no alert', () {
    expect(nextBudgetAlert(s(total: 999999), {}), isNull);
  });

  test('actual over then projected', () {
    final over = s(total: 400000, budget: 300000);
    expect(nextBudgetAlert(over, {}), BudgetAlert.actualOver);
    expect(
      nextBudgetAlert(over, {BudgetAlert.actualOver}),
      BudgetAlert.projectedOver,
    );
    expect(
      nextBudgetAlert(over, {
        BudgetAlert.actualOver,
        BudgetAlert.projectedOver,
      }),
      isNull,
    );
  });

  test('projected only when pace exceeds budget', () {
    // 100000 / 10 * 30 = 300000, not greater than budget
    expect(nextBudgetAlert(s(total: 100000, budget: 300000), {}), isNull);
    expect(
      nextBudgetAlert(s(total: 100001, budget: 300000), {}),
      BudgetAlert.projectedOver,
    );
  });
}
