import 'package:equatable/equatable.dart';

class BudgetPeriod extends Equatable {
  const BudgetPeriod({required this.start, required this.endExclusive});

  final DateTime start;
  final DateTime endExclusive;

  /// 달력 일수. DST 영향을 받지 않도록 y/m/d만으로 계산한다.
  int get totalDays => daysBetween(start, endExclusive);

  /// 기간 시작일 `yyyy-MM-dd`.
  String get key =>
      '${start.year.toString().padLeft(4, '0')}-'
      '${start.month.toString().padLeft(2, '0')}-'
      '${start.day.toString().padLeft(2, '0')}';

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(endExclusive);

  @override
  List<Object?> get props => [start, endExclusive];
}

/// [from]의 날짜부터 [to]의 날짜까지 달력 일수 (to - from).
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

DateTime _startIn(int year, int month, int startDay) {
  // DateTime이 월 범위를 벗어난 값(0, 13 등)을 연도까지 정규화한다.
  final first = DateTime(year, month, 1);
  final last = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(first.year, first.month, startDay < last ? startDay : last);
}

/// [date]가 속한 기간. [startDay]는 1~31이며 그 달에 없으면 말일.
BudgetPeriod periodFor(DateTime date, int startDay) {
  final thisStart = _startIn(date.year, date.month, startDay);
  final start = date.day >= thisStart.day
      ? thisStart
      : _startIn(date.year, date.month - 1, startDay);
  final end = _startIn(start.year, start.month + 1, startDay);
  return BudgetPeriod(start: start, endExclusive: end);
}
