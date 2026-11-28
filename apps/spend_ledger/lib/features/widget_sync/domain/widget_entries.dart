import 'package:intl/intl.dart';

import '../../budget/domain/summary.dart';
import '../../ledger/domain/money_format.dart';
import '../../theme/domain/palette.dart';

String _percent(double x) => (x * 100).floor().toString();

String _named(String name, int amount, bool hide) =>
    hide ? name : '$name ${formatWon(amount)}';

/// ARGB int를 `#AARRGGBB` 대문자 문자열로.
String argbHex(int argb) =>
    '#${(argb & 0xFFFFFFFF).toRadixString(16).toUpperCase().padLeft(8, '0')}';

/// 위젯에 전달할 문자열 맵. 항목이 없으면 빈 문자열.
Map<String, String> widgetEntries(
  LedgerSummary s, {
  required bool hideAmounts,
  required DateTime asOf,
  required AppThemeId themeId,
  required AppThemeMode themeMode,
}) {
  final colors = themeColors(themeId);
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
    'theme.mode': themeMode.name,
    ..._colorEntries(colors),
  };
}

Map<String, String> _colorEntries(ThemeColors c) {
  int pick(Palette p, String token) => switch (token) {
    'widgetBackground' => p.widgetBackground,
    'onSurface' => p.onSurface,
    'subtle' => p.subtle,
    'primary' => p.primary,
    'track' => p.track,
    _ => p.warning,
  };
  const tokens = [
    'widgetBackground',
    'onSurface',
    'subtle',
    'primary',
    'track',
    'warning',
  ];
  return {
    for (final t in tokens) ...{
      'color.$t.light': argbHex(pick(c.light, t)),
      'color.$t.dark': argbHex(pick(c.dark, t)),
    },
  };
}
