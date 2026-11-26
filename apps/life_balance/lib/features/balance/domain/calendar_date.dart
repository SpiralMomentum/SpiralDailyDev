import 'package:equatable/equatable.dart';

/// 시각 없는 로컬 달력 날짜.
class CalendarDate extends Equatable {
  const CalendarDate(this.year, this.month, this.day);

  factory CalendarDate.fromDateTime(DateTime dt) =>
      CalendarDate(dt.year, dt.month, dt.day);

  factory CalendarDate.parse(String yyyyMmDd) {
    final parts = yyyyMmDd.split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid date: $yyyyMmDd');
    }
    return CalendarDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  final int year;
  final int month;
  final int day;

  int get epochDay =>
      DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  CalendarDate addDays(int days) {
    final dt = DateTime.utc(year, month, day + days);
    return CalendarDate(dt.year, dt.month, dt.day);
  }

  /// other - this (일 단위)
  int daysUntil(CalendarDate other) => other.epochDay - epochDay;

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  bool isBefore(CalendarDate o) => epochDay < o.epochDay;

  @override
  List<Object?> get props => [year, month, day];

  @override
  String toString() => toIso();
}
