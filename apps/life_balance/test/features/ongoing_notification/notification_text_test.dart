import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/balance/domain/balance.dart';
import 'package:life_balance/features/balance/domain/balance_format.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/ongoing_notification/domain/notification_text.dart';
import 'package:life_balance/features/tone/domain/phrase_keys.dart';
import 'package:life_balance/features/tone/domain/tone.dart';
import 'package:life_balance/features/tone/domain/tone_table.dart';

ToneTable _load(ToneId id) => parseToneTable(
      id,
      File('assets/tones/${id.name}.json').readAsStringSync(),
    ).dataOrNull!;

void main() {
  const today = CalendarDate(2026, 11, 25);
  const normal =
      Balance(remainingDays: 12345, bonusDays: 0, totalDays: 30000);
  const bonus = Balance(remainingDays: 0, bonusDays: 42, totalDays: 30000);

  test('스토아 비보너스: notification.body 변형에 12,345일이 들어간다', () {
    final stoic = _load(ToneId.stoic);
    final text = notificationText(
      balance: normal,
      unit: BalanceUnit.days,
      tone: stoic,
      today: today,
    );
    expect(text, contains('12,345일'));
    final expected = fillPlaceholders(
      pickPhrase(stoic, PhraseKeys.notificationBody, today),
      {'balance': '12,345일'},
    );
    expect(text, expected);
    expect(text, isNot(contains('{')));
  });

  test('단위 설정을 따른다', () {
    final text = notificationText(
      balance: normal,
      unit: BalanceUnit.weeks,
      tone: _load(ToneId.stoic),
      today: today,
    );
    expect(text, contains('1,763주'));
  });

  test('보너스면 notification.bonus_body를 쓴다', () {
    const tone = ToneTable(id: ToneId.wit, phrases: {
      PhraseKeys.notificationBody: ['잔고 {balance}'],
      PhraseKeys.notificationBonusBody: ['보너스 {bonus}'],
    });
    expect(
      notificationText(
          balance: bonus, unit: BalanceUnit.days, tone: tone, today: today),
      '보너스 +42일',
    );
    expect(
      notificationText(
          balance: normal, unit: BalanceUnit.days, tone: tone, today: today),
      '잔고 12,345일',
    );
  });

  test('3말투 모두 자리표시자가 남지 않는다', () {
    for (final id in ToneId.values) {
      final t = _load(id);
      for (final b in [normal, bonus]) {
        for (var d = 0; d < 7; d++) {
          final text = notificationText(
            balance: b,
            unit: BalanceUnit.days,
            tone: t,
            today: today.addDays(d),
          );
          expect(text, isNot(contains('{')), reason: '${id.name} $text');
        }
      }
    }
  });
}
