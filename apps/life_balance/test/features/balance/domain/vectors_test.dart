import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/balance/domain/balance_calculator.dart';
import 'package:life_balance/features/balance/domain/balance_format.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/maturity_schedule.dart';

void main() {
  final vectors = jsonDecode(File('test_vectors/balance_vectors.json')
      .readAsStringSync()) as List<dynamic>;

  test('at least 6 vectors', () => expect(vectors.length >= 6, isTrue));

  for (final raw in vectors) {
    final v = raw as Map<String, dynamic>;
    test(v['name'] as String, () {
      final birth = CalendarDate.parse(v['birth'] as String);
      final today = CalendarDate.parse(v['today'] as String);
      final schedule = (v['schedule'] as List<dynamic>)
          .map((e) => ScheduleEntry(
                validFrom: CalendarDate.parse(e['validFrom'] as String),
                maturity: CalendarDate.parse(e['maturity'] as String),
              ))
          .toList();
      final unit = BalanceUnit.values.byName(v['unit'] as String);
      final expected = v['expected'] as Map<String, dynamic>;

      final entry = entryFor(schedule, today);
      final b = computeBalance(
          birth: birth, maturity: entry.maturity, today: today);

      expect(b.remainingDays, expected['remainingDays']);
      expect(b.bonusDays, expected['bonusDays']);
      expect(formatBalanceValue(b, unit), expected['display']);
      expect((usedRatio(b) * 1000).round(), expected['usedRatioPermille']);
    });
  }
}
