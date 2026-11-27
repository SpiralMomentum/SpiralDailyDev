import 'balance.dart';

enum BalanceUnit { days, weeks, years, percent }

String _grouped(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// 정수 연산으로 소수 1자리 내림 (부동소수 오차 회피).
String _tenths(int tenths) => '${tenths ~/ 10}.${tenths % 10}';

String formatBalanceValue(Balance b, BalanceUnit unit) {
  final bonus = b.isBonus;
  final days = bonus ? b.bonusDays : b.remainingDays;
  final prefix = bonus ? '+' : '';
  switch (unit) {
    case BalanceUnit.days:
      return '$prefix${_grouped(days)}일';
    case BalanceUnit.weeks:
      return '$prefix${_grouped(days ~/ 7)}주';
    case BalanceUnit.years:
      // 0.1년 단위: days * 10 / 365.2425 = days * 100000 / 3652425 (내림)
      return '$prefix${_tenths(days * 100000 ~/ 3652425)}년';
    case BalanceUnit.percent:
      if (bonus) return '+${_grouped(days)}일';
      final permille = b.totalDays > 0 ? days * 1000 ~/ b.totalDays : 0;
      return '${_tenths(permille)}%';
  }
}

double usedRatio(Balance b) {
  if (b.isBonus || b.totalDays <= 0) return 1.0;
  return (1 - b.remainingDays / b.totalDays).clamp(0.0, 1.0);
}
