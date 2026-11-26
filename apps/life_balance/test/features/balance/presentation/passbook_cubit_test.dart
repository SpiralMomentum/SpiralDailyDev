import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/balance/presentation/passbook_cubit.dart';
import 'package:life_balance/features/profile/domain/settings.dart';
import 'package:life_balance/features/tone/domain/tone.dart';
import 'package:life_balance/features/tone/domain/tone_table.dart';

import '../../../helpers/fake_life_table.dart';

const tone = ToneTable(
  id: ToneId.stoic,
  phrases: {
    'main.title': ['인생잔고'],
    'main.balance_label': ['남은 날'],
    'main.opened_label': ['계좌 개설일'],
    'main.maturity_label': ['만기일'],
    'main.withdrawal': ['오늘 출금 -1일'],
    'main.bonus_notice': ['덤 {bonus}'],
  },
);

PassbookCubit make(CalendarDate Function() today, {double? manual}) =>
    PassbookCubit(
      profile: Profile(
        birthDate: const CalendarDate(2000, 1, 1),
        sex: Sex.male,
        countryCode: 'KR',
        manualLifespanYears: manual,
      ),
      settings: AppSettings.defaults,
      table: FakeLifeTable({for (var a = 0; a <= 150; a++) a: 53.0}),
      tone: tone,
      today: today,
    );

void main() {
  test('initial state has display, dates and withdrawal phrase', () {
    final c = make(() => const CalendarDate(2026, 1, 1));
    final s = c.state;
    expect(s.birth, const CalendarDate(2000, 1, 1));
    expect(s.maturity, const CalendarDate(2079, 1, 1));
    expect(s.display, '19,358일');
    expect(s.balance.remainingDays, 19358);
    expect(s.usedRatio, closeTo(0.3, 0.05));
    expect(s.phrases['main.withdrawal'], '오늘 출금 -1일');
    expect(s.phrases.containsKey('main.bonus_notice'), isFalse);
  });

  test('refresh reflects a changed date', () {
    var now = const CalendarDate(2026, 1, 1);
    final c = make(() => now);
    final before = c.state.balance.remainingDays;
    now = const CalendarDate(2026, 1, 2);
    c.refresh();
    expect(c.state.balance.remainingDays, before - 1);
    expect(c.state.today, const CalendarDate(2026, 1, 2));
  });

  test('refresh with the same date does not emit', () async {
    final c = make(() => const CalendarDate(2026, 1, 1));
    c.refresh(); // bloc은 첫 emit만 동일 상태도 통과시킨다
    await Future<void>.delayed(Duration.zero);
    final emitted = <Object>[];
    final sub = c.stream.listen(emitted.add);
    c.refresh();
    await Future<void>.delayed(Duration.zero);
    expect(emitted, isEmpty);
    await sub.cancel();
  });

  test('bonus: bonus_notice filled, withdrawal hidden, ratio 1.0', () {
    final c = make(() => const CalendarDate(2026, 1, 1), manual: 20);
    final s = c.state;
    expect(s.balance.isBonus, isTrue);
    expect(s.display.startsWith('+'), isTrue);
    expect(s.phrases['main.bonus_notice'], '덤 ${s.display}');
    expect(s.phrases.containsKey('main.withdrawal'), isFalse);
    expect(s.usedRatio, 1.0);
  });
}
