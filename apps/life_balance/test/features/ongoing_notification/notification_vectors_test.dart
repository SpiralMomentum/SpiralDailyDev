import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/balance/domain/balance_calculator.dart';
import 'package:life_balance/features/balance/domain/balance_format.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/maturity_schedule.dart';
import 'package:life_balance/features/ongoing_notification/domain/notification_text.dart';
import 'package:life_balance/features/tone/domain/tone.dart';
import 'package:life_balance/features/tone/domain/tone_table.dart';

/// Kotlin `OngoingNotification`(재부팅 후 네이티브 게시)과 같은 벡터를 검증한다.
void main() {
  final vectors = jsonDecode(
    File('test_vectors/notification_vectors.json').readAsStringSync(),
  ) as List<dynamic>;

  test('bonus/non-bonus vectors exist', () {
    final names = [for (final v in vectors) (v as Map)['name'] as String];
    expect(names, containsAll(['days_body', 'bonus_days']));
  });

  for (final raw in vectors) {
    final v = raw as Map<String, dynamic>;
    test(v['name'] as String, () {
      final today = CalendarDate.parse(v['today'] as String);
      final schedule = [
        for (final e in v['schedule'] as List<dynamic>)
          ScheduleEntry(
            validFrom: CalendarDate.parse(e['validFrom'] as String),
            maturity: CalendarDate.parse(e['maturity'] as String),
          ),
      ];
      final phrases = {
        for (final p in (v['phrases'] as Map<String, dynamic>).entries)
          p.key: (p.value as List<dynamic>).cast<String>(),
      };
      final balance = computeBalance(
        birth: CalendarDate.parse(v['birth'] as String),
        maturity: entryFor(schedule, today).maturity,
        today: today,
      );
      expect(
        notificationText(
          balance: balance,
          unit: BalanceUnit.values.byName(v['unit'] as String),
          tone: ToneTable(id: ToneId.wit, phrases: phrases),
          today: today,
        ),
        v['expected'],
      );
    });
  }
}
