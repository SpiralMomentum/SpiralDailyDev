import 'summary.dart';

enum BudgetAlert { projectedOver, actualOver }

/// 아직 보내지 않은 알림 중 다음에 보낼 것. 없으면 null.
BudgetAlert? nextBudgetAlert(LedgerSummary s, Set<BudgetAlert> sent) {
  final budget = s.budget;
  if (budget == null) return null;
  if (s.periodTotal > budget && !sent.contains(BudgetAlert.actualOver)) {
    return BudgetAlert.actualOver;
  }
  final projected = s.periodTotal / s.elapsedDays * s.period.totalDays;
  if (projected > budget && !sent.contains(BudgetAlert.projectedOver)) {
    return BudgetAlert.projectedOver;
  }
  return null;
}
