import 'package:equatable/equatable.dart';

import '../../life_table/domain/life_table.dart';
import 'balance_calculator.dart';
import 'calendar_date.dart';
import 'profile.dart';

class ScheduleEntry extends Equatable {
  const ScheduleEntry({required this.validFrom, required this.maturity});

  final CalendarDate validFrom;
  final CalendarDate maturity;

  Map<String, String> toJson() =>
      {'validFrom': validFrom.toIso(), 'maturity': maturity.toIso()};

  @override
  List<Object?> get props => [validFrom, maturity];
}

List<ScheduleEntry> buildSchedule({
  required Profile profile,
  required CalendarDate today,
  required LifeTable table,
  int years = 10,
}) {
  final birth = profile.birthDate;
  if (profile.manualLifespanYears != null) {
    return [
      ScheduleEntry(
        validFrom: birth,
        maturity: maturityDate(profile: profile, today: today, table: table),
      ),
    ];
  }
  final age = ageOn(birth, today);
  return List.generate(years, (i) {
    final from = birthdayOf(birth, birth.year + age + i);
    return ScheduleEntry(
      validFrom: from,
      maturity: maturityDate(profile: profile, today: from, table: table),
    );
  });
}

ScheduleEntry entryFor(List<ScheduleEntry> schedule, CalendarDate today) {
  var result = schedule.first;
  for (final e in schedule) {
    if (e.validFrom.isBefore(today) || e.validFrom == today) {
      result = e;
    }
  }
  return result;
}
