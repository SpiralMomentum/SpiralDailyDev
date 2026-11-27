import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/ongoing_notification/data/ongoing_notifier.dart';
import 'package:life_balance/features/profile/domain/settings.dart';
import 'package:life_balance/features/tone/domain/phrase_keys.dart';
import 'package:life_balance/features/tone/domain/tone.dart';
import 'package:life_balance/features/tone/domain/tone_table.dart';
import 'package:life_balance/features/widget_sync/data/home_widget_sync.dart';
import 'package:life_balance/features/widget_sync/data/widget_payload.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_life_table.dart';

class _MockGateway extends Mock implements WidgetGateway {}

class _MockNotifier extends Mock implements OngoingNotifier {}

void main() {
  final table = FakeLifeTable({for (var a = 0; a <= 130; a++) a: 50.0});
  const tone = ToneTable(id: ToneId.stoic, phrases: {
    PhraseKeys.notificationBody: ['잔고 {balance}'],
    PhraseKeys.notificationBonusBody: ['보너스 {bonus}'],
  });
  const profile = Profile(
    birthDate: CalendarDate(1990, 5, 1),
    sex: Sex.male,
    countryCode: 'KR',
  );
  const today = CalendarDate(2026, 11, 25);

  late _MockGateway widgets;
  late _MockNotifier notifier;

  setUp(() {
    widgets = _MockGateway();
    notifier = _MockNotifier();
    when(() => widgets.save(any())).thenAnswer((_) async {});
    when(() => widgets.refresh()).thenAnswer((_) async {});
    when(() => notifier.show(any())).thenAnswer((_) async {});
    when(() => notifier.cancel()).thenAnswer((_) async {});
  });

  Future<void> run(AppSettings settings, {Profile p = profile}) =>
      syncDerivedOutputs(
        profile: p,
        settings: settings,
        table: table,
        tone: tone,
        today: today,
        widgets: widgets,
        notifier: notifier,
      );

  test('알림 켜짐: 위젯 save/refresh 후 show 1회', () async {
    await run(const AppSettings(ongoingNotification: true));

    final expected = buildWidgetPayload(
      profile: profile,
      settings: const AppSettings(ongoingNotification: true),
      table: table,
      tone: tone,
      today: today,
    );
    verify(() => widgets.save(expected.toEntries())).called(1);
    verify(() => widgets.refresh()).called(1);
    // 36세(2026-05-01 기준) + round(50 * 365.2425) = 18,262일 -> 만기 2076-04-30.
    // 2026-05-01 ~ 2026-11-25 = 208일 경과 -> 18,262 - 208 = 18,054일
    verify(() => notifier.show('잔고 18,054일')).called(1);
    verifyNever(() => notifier.cancel());
  });

  test('알림 꺼짐: 위젯 save/refresh 후 cancel 1회', () async {
    await run(const AppSettings(ongoingNotification: false));

    verify(() => widgets.save(any())).called(1);
    verify(() => widgets.refresh()).called(1);
    verify(() => notifier.cancel()).called(1);
    verifyNever(() => notifier.show(any()));
  });

  test('보너스 구간이면 bonus_body', () async {
    await run(
      const AppSettings(),
      p: profile.copyWith(manualLifespanYears: 30),
    );
    // 만기 2020-05-01 -> 보너스 일수
    final bonus = const CalendarDate(2020, 5, 1).daysUntil(today);
    final grouped = bonus.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    verify(() => notifier.show('보너스 +$grouped일')).called(1);
  });
}
