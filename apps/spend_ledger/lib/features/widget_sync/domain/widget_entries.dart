import 'package:intl/intl.dart';

import '../../budget/domain/summary.dart';
import '../../ledger/domain/money_format.dart';

String _percent(double x) => (x * 100).floor().toString();

String _named(String name, int amount, bool hide) =>
    hide ? name : '$name ${formatWon(amount)}';

/// 위젯에 전달할 문자열 맵. 항목이 없으면 빈 문자열.
Map<String, String> widgetEntries(
  LedgerSummary s, {
  required bool hideAmounts,
  required DateTime asOf,
}) {
  String money(int? v) => hideAmounts || v == null ? '' : formatWon(v);
  final ratio = s.budgetRatio;
  final top = s.topMerchants;
  final recent = s.recent;
  String topAt(int i) =>
      i < top.length ? _named(top[i].name, top[i].amount, hideAmounts) : '';
  String recentAt(int i) => i < recent.length
      ? _named(recent[i].counterparty, recent[i].amount, hideAmounts)
      : '';

  return {
    'total': money(s.periodTotal),
    'ratio': ratio == null ? '' : _percent(ratio),
    'today': money(s.todayTotal),
    'daily': money(s.dailyAllowance),
    'elapsed': _percent(s.elapsedRatio),
    for (var i = 0; i < 3; i++) 'top${i + 1}': topAt(i),
    for (var i = 0; i < 3; i++) 'recent${i + 1}': recentAt(i),
    'pending': s.pendingCount.toString(),
    'asOf': DateFormat('M/d HH:mm').format(asOf),
  };
}
