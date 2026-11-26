import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/balance/domain/balance.dart';
import 'package:life_balance/features/balance/domain/balance_format.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/maturity_schedule.dart';
import 'package:life_balance/features/balance/domain/profile.dart';

import '../../../helpers/fake_life_table.dart';

void main() {
  const normal =
      Balance(remainingDays: 12345, bonusDays: 0, totalDays: 30000);
  const bonus = Balance(remainingDays: 0, bonusDays: 400, totalDays: 30000);

  test('formatBalanceValue normal', () {
    expect(formatBalanceValue(normal, BalanceUnit.days), '12,345일');
    expect(formatBalanceValue(normal, BalanceUnit.weeks), '1,763주');
    expect(formatBalanceValue(normal, BalanceUnit.years), '33.7년');
    expect(formatBalanceValue(normal, BalanceUnit.percent), '41.1%');
  });

  test('formatBalanceValue bonus', () {
    expect(formatBalanceValue(bonus, BalanceUnit.days), '+400일');
    expect(formatBalanceValue(bonus, BalanceUnit.weeks), '+57주');
    expect(formatBalanceValue(bonus, BalanceUnit.years), '+1.0년');
    expect(formatBalanceValue(bonus, BalanceUnit.percent), '+400일');
  });

  test('usedRatio', () {
    expect(usedRatio(normal), closeTo(0.5885, 1e-9));
    expect(usedRatio(bonus), 1.0);
  });

  final table = FakeLifeTable({for (var a = 0; a <= 100; a++) a: 40.0});
  const birth = CalendarDate(1990, 5, 10);
  const profile = Profile(birthDate: birth, sex: Sex.male, countryCode: 'KR');

  test('buildSchedule table mode', () {
    final s = buildSchedule(
      profile: profile,
      today: const CalendarDate(2026, 6, 1),
      table: table,
    );
    expect(s.length, 10);
    expect(s.first.validFrom, const CalendarDate(2026, 5, 10));
    expect(s[1].validFrom, const CalendarDate(2027, 5, 10));
    expect(s.last.validFrom, const CalendarDate(2035, 5, 10));
    // age 36, e=40 -> 2026-05-10 + 40*365.2425 = 14609.7 -> round 14610 days
    expect(s.first.maturity, const CalendarDate(2026, 5, 10).addDays(14610));
    expect(s[1].maturity, const CalendarDate(2027, 5, 10).addDays(14610));
  });

  test('buildSchedule manual mode is a single entry from birth', () {
    final s = buildSchedule(
      profile: profile.copyWith(manualLifespanYears: 80),
      today: const CalendarDate(2026, 6, 1),
      table: table,
    );
    expect(s.length, 1);
    expect(s.single.validFrom, birth);
    expect(s.single.maturity, const CalendarDate(2070, 5, 10));
  });

  test('entryFor', () {
    final s = buildSchedule(
      profile: profile,
      today: const CalendarDate(2026, 6, 1),
      table: table,
    );
    expect(entryFor(s, const CalendarDate(2027, 5, 10)), s[1]);
    expect(entryFor(s, const CalendarDate(2027, 5, 9)), s[0]);
    expect(entryFor(s, const CalendarDate(2000, 1, 1)), s[0]);
    expect(s.first.toJson(),
        {'validFrom': '2026-05-10', 'maturity': s.first.maturity.toIso()});
  });
}
