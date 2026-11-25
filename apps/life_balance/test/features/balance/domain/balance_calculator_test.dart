import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/balance/domain/balance_calculator.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/life_table/domain/life_table.dart';

class FakeLifeTable implements LifeTable {
  FakeLifeTable(this.values);
  final Map<int, double> values;

  @override
  double remainingYears({
    required String countryCode,
    required Sex sex,
    required int age,
  }) =>
      values[age]!;

  @override
  List<String> get countryCodes => const ['KR'];
}

void main() {
  const birth = CalendarDate(1990, 5, 10);
  const profile = Profile(birthDate: birth, sex: Sex.male, countryCode: 'KR');

  test('ageOn', () {
    expect(ageOn(birth, const CalendarDate(2026, 5, 9)), 35);
    expect(ageOn(birth, const CalendarDate(2026, 5, 10)), 36);
  });

  test('feb29 birthday in common year', () {
    const b = CalendarDate(2000, 2, 29);
    expect(ageOn(b, const CalendarDate(2027, 2, 28)), 27);
    expect(birthdayOf(b, 2027), const CalendarDate(2027, 2, 28));
    expect(ageOn(b, const CalendarDate(2027, 2, 27)), 26);
  });

  test('maturityDate table mode', () {
    final table = FakeLifeTable({36: 45.0});
    final m = maturityDate(
        profile: profile, today: const CalendarDate(2026, 11, 25), table: table);
    expect(m, const CalendarDate(2026, 5, 10).addDays(16436));
  });

  test('maturity anchored to birthday not today', () {
    final table = FakeLifeTable({36: 45.0});
    final a = maturityDate(
        profile: profile, today: const CalendarDate(2026, 11, 25), table: table);
    final b = maturityDate(
        profile: profile, today: const CalendarDate(2027, 3, 1), table: table);
    expect(a, b);
  });

  test('manual mode', () {
    final m = maturityDate(
      profile: profile.copyWith(manualLifespanYears: 80.5),
      today: const CalendarDate(2026, 11, 25),
      table: FakeLifeTable({}),
    );
    expect(m, const CalendarDate(2070, 5, 10).addDays(183));
  });

  test('estimatedLifespanYears rounds to 1 decimal', () {
    final table = FakeLifeTable({36: 45.04});
    expect(
        estimatedLifespanYears(
            profile: profile,
            today: const CalendarDate(2026, 11, 25),
            table: table),
        81.0);
  });

  group('computeBalance', () {
    const today = CalendarDate(2026, 11, 25);
    test('future maturity', () {
      final b = computeBalance(
          birth: birth, maturity: today.addDays(100), today: today);
      expect(b.remainingDays, 100);
      expect(b.bonusDays, 0);
      expect(b.isBonus, false);
    });
    test('maturity today', () {
      final b = computeBalance(birth: birth, maturity: today, today: today);
      expect(b.remainingDays, 0);
      expect(b.isBonus, true);
    });
    test('past maturity', () {
      final b = computeBalance(
          birth: birth, maturity: today.addDays(-5), today: today);
      expect(b.remainingDays, 0);
      expect(b.bonusDays, 5);
      expect(b.isBonus, true);
    });
  });

  test('age over 100 uses 100', () {
    final table = FakeLifeTable({100: 2.0});
    const old = Profile(
        birthDate: CalendarDate(1920, 1, 1),
        sex: Sex.female,
        countryCode: 'KR');
    const today = CalendarDate(2023, 6, 1);
    expect(ageOn(old.birthDate, today), 103);
    expect(() => maturityDate(profile: old, today: today, table: table),
        returnsNormally);
  });
}
