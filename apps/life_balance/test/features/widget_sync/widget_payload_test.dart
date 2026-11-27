import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/balance/domain/balance_format.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/profile/domain/settings.dart';
import 'package:life_balance/features/tone/domain/tone.dart';
import 'package:life_balance/features/tone/domain/tone_table.dart';
import 'package:life_balance/features/widget_sync/data/widget_payload.dart';

import '../../helpers/fake_life_table.dart';

void main() {
  final table = FakeLifeTable({for (var a = 0; a <= 130; a++) a: 50.0});
  final tone = ToneTable(
    id: ToneId.wit,
    phrases: const {
      'widget.small_label': ['a'],
      'widget.medium_label': ['b'],
      'widget.withdrawal': ['c'],
      'widget.bonus_label': ['d'],
      'notification.body': ['n {balance}'],
      'notification.bonus_body': ['nb {bonus}'],
      'main.title': ['x'],
    },
  );
  const profile = Profile(
    birthDate: CalendarDate(1990, 5, 1),
    sex: Sex.male,
    countryCode: 'KR',
  );
  const settings = AppSettings(unit: BalanceUnit.weeks, tone: ToneId.wit);
  final payload = buildWidgetPayload(
    profile: profile,
    settings: settings,
    table: table,
    tone: tone,
    today: const CalendarDate(2026, 11, 25),
  );
  final e = payload.toEntries();

  test('key set matches the Kotlin contract exactly', () {
    expect(e.keys.toSet(), {
      'lb_schedule',
      'lb_birth',
      'lb_unit',
      'lb_tone',
      'lb_colors_light',
      'lb_colors_dark',
      'lb_phrases',
      'lb_notify',
    });
  });

  test('schedule has 10 entries with ISO dates', () {
    final list = jsonDecode(e['lb_schedule']!) as List;
    expect(list, hasLength(10));
    expect((list.first as Map).keys, containsAll(['validFrom', 'maturity']));
    expect((list.first as Map)['validFrom'], '2026-05-01');
  });

  test('scalar entries', () {
    expect(e['lb_birth'], '1990-05-01');
    expect(e['lb_unit'], 'weeks');
    expect(e['lb_tone'], 'wit');
  });

  test('colors are ARGB ints', () {
    final light = jsonDecode(e['lb_colors_light']!) as Map;
    final dark = jsonDecode(e['lb_colors_dark']!) as Map;
    expect(light, {'bg': 0xFFFFF4F0, 'fg': 0xFF3A3A3A, 'accent': 0xFFFF7F6E});
    expect(dark['bg'], 0xFF2A1F1D);
  });

  test('phrases contain the four widget keys and two notification keys', () {
    final p = jsonDecode(e['lb_phrases']!) as Map;
    expect(p.keys.toSet(), {
      'widget.small_label',
      'widget.medium_label',
      'widget.withdrawal',
      'widget.bonus_label',
      'notification.body',
      'notification.bonus_body',
    });
    expect(p['widget.small_label'], ['a']);
    expect(p['notification.body'], ['n {balance}']);
    expect(p['notification.bonus_body'], ['nb {bonus}']);
  });

  test('lb_notify follows the ongoing notification setting', () {
    expect(e['lb_notify'], '1');
    final off = buildWidgetPayload(
      profile: profile,
      settings: settings.copyWith(ongoingNotification: false),
      table: table,
      tone: tone,
      today: const CalendarDate(2026, 11, 25),
    ).toEntries();
    expect(off['lb_notify'], '0');
  });
}
