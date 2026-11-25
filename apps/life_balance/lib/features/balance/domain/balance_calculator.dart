import '../../life_table/domain/life_table.dart';
import 'balance.dart';
import 'calendar_date.dart';
import 'profile.dart';

const double daysPerYear = 365.2425;
const int _maxTableAge = 100;

int ageOn(CalendarDate birth, CalendarDate today) {
  final age = today.year - birth.year;
  return today.isBefore(birthdayOf(birth, today.year)) ? age - 1 : age;
}

/// 2/29생은 평년에 2/28.
CalendarDate birthdayOf(CalendarDate birth, int year) {
  if (birth.month == 2 && birth.day == 29 && !_isLeap(year)) {
    return CalendarDate(year, 2, 28);
  }
  return CalendarDate(year, birth.month, birth.day);
}

bool _isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

double _remaining(Profile p, int age, LifeTable table) => table.remainingYears(
      countryCode: p.countryCode,
      sex: p.sex,
      age: age > _maxTableAge ? _maxTableAge : age,
    );

CalendarDate maturityDate({
  required Profile profile,
  required CalendarDate today,
  required LifeTable table,
}) {
  final birth = profile.birthDate;
  final manual = profile.manualLifespanYears;
  if (manual != null) {
    final whole = manual.floor();
    final frac = manual - whole;
    return birthdayOf(birth, birth.year + whole)
        .addDays((frac * daysPerYear).round());
  }
  final age = ageOn(birth, today);
  final e = _remaining(profile, age, table);
  return birthdayOf(birth, birth.year + age)
      .addDays((e * daysPerYear).round());
}

double estimatedLifespanYears({
  required Profile profile,
  required CalendarDate today,
  required LifeTable table,
}) {
  final manual = profile.manualLifespanYears;
  if (manual != null) return (manual * 10).round() / 10;
  final age = ageOn(profile.birthDate, today);
  final e = _remaining(profile, age, table);
  return ((age + e) * 10).round() / 10;
}

Balance computeBalance({
  required CalendarDate birth,
  required CalendarDate maturity,
  required CalendarDate today,
}) {
  final left = today.daysUntil(maturity);
  return Balance(
    remainingDays: left > 0 ? left : 0,
    bonusDays: left < 0 ? -left : 0,
    totalDays: birth.daysUntil(maturity),
  );
}
