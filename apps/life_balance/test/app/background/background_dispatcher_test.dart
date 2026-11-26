import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/app/background/background_dispatcher.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/life_table/domain/life_table.dart';
import 'package:life_balance/features/ongoing_notification/data/midnight_scheduler.dart';
import 'package:life_balance/features/ongoing_notification/data/ongoing_notifier.dart';
import 'package:life_balance/features/profile/domain/profile_repository.dart';
import 'package:life_balance/features/profile/domain/settings.dart';
import 'package:life_balance/features/tone/domain/phrase_keys.dart';
import 'package:life_balance/features/tone/domain/tone.dart';
import 'package:life_balance/features/tone/domain/tone_table.dart';
import 'package:life_balance/features/widget_sync/data/home_widget_sync.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_life_table.dart';

class _MockRepo extends Mock implements ProfileRepository {}

class _MockGateway extends Mock implements WidgetGateway {}

class _MockNotifier extends Mock implements OngoingNotifier {}

class _MockScheduler extends Mock implements RefreshScheduler {}

void main() {
  final now = DateTime(2026, 11, 26, 0, 1, 5);
  const profile = Profile(
    birthDate: CalendarDate(1990, 5, 1),
    sex: Sex.female,
    countryCode: 'KR',
  );
  const tone = ToneTable(id: ToneId.wit, phrases: {
    PhraseKeys.notificationBody: ['잔고 {balance}'],
    PhraseKeys.notificationBonusBody: ['보너스 {bonus}'],
  });

  late _MockRepo repo;
  late _MockGateway widgets;
  late _MockNotifier notifier;
  late _MockScheduler scheduler;
  late List<ToneId> toneRequests;
  LifeTable? table;

  setUp(() {
    repo = _MockRepo();
    widgets = _MockGateway();
    notifier = _MockNotifier();
    scheduler = _MockScheduler();
    toneRequests = [];
    table = FakeLifeTable({for (var a = 0; a <= 130; a++) a: 50.0});
    when(() => repo.loadProfile()).thenAnswer((_) async => profile);
    when(() => repo.loadSettings())
        .thenAnswer((_) async => const AppSettings(tone: ToneId.wit));
    when(() => widgets.save(any())).thenAnswer((_) async {});
    when(() => widgets.refresh()).thenAnswer((_) async {});
    when(() => notifier.show(any())).thenAnswer((_) async {});
    when(() => notifier.cancel()).thenAnswer((_) async {});
    when(() => scheduler.ensureScheduled(any(),
            fromMidnightJob: any(named: 'fromMidnightJob')))
        .thenAnswer((_) async {});
  });

  BackgroundDeps deps() => BackgroundDeps(
        profiles: repo,
        loadLifeTable: () async => table,
        loadTone: (id) async {
          toneRequests.add(id);
          return tone;
        },
        widgets: widgets,
        notifier: notifier,
        scheduler: scheduler,
        now: () => now,
      );

  test('lb_midnight: 저장소에서 읽어 동기화 후 다음 자정 재예약', () async {
    final ok = await runBackgroundTask(RefreshTasks.midnight, deps());

    expect(ok, isTrue);
    expect(toneRequests, [ToneId.wit]);
    verify(() => widgets.save(any())).called(1);
    verify(() => widgets.refresh()).called(1);
    verify(() => notifier.show(any(that: startsWith('잔고 ')))).called(1);
    verify(() => scheduler.ensureScheduled(now, fromMidnightJob: true))
        .called(1);
  });

  test('lb_hourly: 동기화만 하고 재예약하지 않는다', () async {
    final ok = await runBackgroundTask(RefreshTasks.hourly, deps());

    expect(ok, isTrue);
    verify(() => notifier.show(any())).called(1);
    verifyNever(() => scheduler.ensureScheduled(any(),
        fromMidnightJob: any(named: 'fromMidnightJob')));
  });

  test('프로필이 없으면 동기화하지 않지만 자정 재예약은 한다', () async {
    when(() => repo.loadProfile()).thenAnswer((_) async => null);

    final ok = await runBackgroundTask(RefreshTasks.midnight, deps());

    expect(ok, isTrue);
    verifyNever(() => widgets.save(any()));
    verifyNever(() => notifier.show(any()));
    verify(() => scheduler.ensureScheduled(now, fromMidnightJob: true))
        .called(1);
  });

  test('생명표 로드 실패면 동기화를 건너뛴다', () async {
    table = null;

    final ok = await runBackgroundTask(RefreshTasks.midnight, deps());

    expect(ok, isTrue);
    verifyNever(() => widgets.save(any()));
    verify(() => scheduler.ensureScheduled(now, fromMidnightJob: true))
        .called(1);
  });

  test('동기화 중 예외가 나도 자정 재예약은 하고 false를 돌려준다', () async {
    when(() => widgets.save(any())).thenThrow(StateError('boom'));

    final ok = await runBackgroundTask(RefreshTasks.midnight, deps());

    expect(ok, isFalse);
    verify(() => scheduler.ensureScheduled(now, fromMidnightJob: true))
        .called(1);
  });
}
