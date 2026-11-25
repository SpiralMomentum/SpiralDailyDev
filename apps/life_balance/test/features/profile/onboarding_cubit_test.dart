import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/life_table/domain/life_table.dart';
import 'package:life_balance/features/profile/domain/profile_repository.dart';
import 'package:life_balance/features/profile/domain/settings.dart';
import 'package:life_balance/features/profile/presentation/onboarding/onboarding_cubit.dart';
import 'package:life_balance/features/profile/presentation/onboarding/onboarding_state.dart';
import 'package:life_balance/features/tone/domain/tone.dart';
import 'package:mocktail/mocktail.dart';

class MockRepo extends Mock implements ProfileRepository {}

class _Table implements LifeTable {
  @override
  List<String> get countryCodes => const ['KR', 'JP', 'US'];

  @override
  double remainingYears({
    required String countryCode,
    required Sex sex,
    required int age,
  }) => 40.0;
}

const _today = CalendarDate(2026, 6, 15);
const _birth = CalendarDate(1990, 1, 1);

void main() {
  late MockRepo repo;
  late List<(Profile, AppSettings)> completed;

  setUpAll(() {
    registerFallbackValue(
      const Profile(birthDate: _birth, sex: Sex.male, countryCode: 'KR'),
    );
    registerFallbackValue(AppSettings.defaults);
  });

  setUp(() {
    repo = MockRepo();
    completed = [];
    when(() => repo.saveProfile(any())).thenAnswer((_) async {});
    when(() => repo.saveSettings(any())).thenAnswer((_) async {});
    when(
      () => repo.loadSettings(),
    ).thenAnswer((_) async => AppSettings.defaults);
  });

  OnboardingCubit build({
    String? device = 'KR',
    Future<void> Function(Profile, AppSettings)? onComplete,
  }) => OnboardingCubit(
    repo: repo,
    table: _Table(),
    today: () => _today,
    deviceCountry: device,
    onComplete: onComplete ?? (p, s) async => completed.add((p, s)),
  );

  group('초기 상태', () {
    test('기기 국가가 테이블에 있으면 사용', () {
      expect(build(device: 'JP').state.countryCode, 'JP');
    });
    test('테이블에 없으면 KR', () {
      expect(build(device: 'ZZ').state.countryCode, 'KR');
      expect(build(device: null).state.countryCode, 'KR');
    });
  });

  blocTest<OnboardingCubit, OnboardingState>(
    '미래 생년월일은 오류 상태, 값 저장 안 됨',
    build: build,
    act: (c) => c.setBirthDate(const CalendarDate(2026, 6, 16)),
    expect: () => [
      isA<OnboardingState>()
          .having((s) => s.error, 'error', OnboardingError.futureBirthDate)
          .having((s) => s.birthDate, 'birth', isNull),
    ],
  );

  test('오늘 생년월일은 허용, 이후 입력하면 오류 해제', () {
    final c = build();
    c.setBirthDate(const CalendarDate(2026, 6, 16));
    c.setBirthDate(_today);
    expect(c.state.birthDate, _today);
    expect(c.state.error, isNull);
  });

  test('생년월일 없이 next()는 진행하지 않음', () {
    final c = build()..next();
    expect(c.state.step, OnboardingStep.birthDate);
  });

  test('lifespan 단계 진입 시 estimatedLifespan 채워짐(age 36 + 40 = 76.0)', () {
    final c = build()
      ..setBirthDate(_birth)
      ..next()
      ..next();
    expect(c.state.step, OnboardingStep.country);
    expect(c.state.estimatedLifespanYears, isNull);
    c.next();
    expect(c.state.step, OnboardingStep.lifespan);
    expect(c.state.estimatedLifespanYears, 76.0);
  });

  test('back()은 이전 단계로, 첫 단계와 done에서는 무시', () {
    final c = build()
      ..setBirthDate(_birth)
      ..next()
      ..back();
    expect(c.state.step, OnboardingStep.birthDate);
    c.back();
    expect(c.state.step, OnboardingStep.birthDate);
  });

  test('tone 단계에서 next()는 done으로 가지 않음', () {
    final c = build()..setBirthDate(_birth);
    for (var i = 0; i < 6; i++) {
      c.next();
    }
    expect(c.state.step, OnboardingStep.tone);
  });

  group('수동 기대수명 검증', () {
    for (final bad in [0.0, -5.0, 150.1, double.nan, double.infinity]) {
      test('$bad 는 오류, 저장 안 됨', () {
        final c = build()..setManualLifespan(bad);
        expect(c.state.error, OnboardingError.invalidLifespan);
        expect(c.state.manualLifespanYears, isNull);
      });
    }
    test('150과 현재 나이보다 작은 값(20)은 허용', () {
      final c = build()..setManualLifespan(150);
      expect(c.state.manualLifespanYears, 150);
      c.setManualLifespan(20);
      expect(c.state.manualLifespanYears, 20);
      expect(c.state.error, isNull);
    });
    test('잘못된 값은 이전 값을 유지하고 null은 해제', () {
      final c = build()
        ..setManualLifespan(80)
        ..setManualLifespan(-1);
      expect(c.state.manualLifespanYears, 80);
      c.setManualLifespan(null);
      expect(c.state.manualLifespanYears, isNull);
    });
  });

  test(
    'complete: 수동값 포함 saveProfile, saveSettings, onComplete, done+첫 잔고',
    () async {
      final c = build()
        ..setBirthDate(_birth)
        ..setSex(Sex.female)
        ..setCountry('JP')
        ..setManualLifespan(90)
        ..setTone(ToneId.wit);
      await c.complete();

      const expected = Profile(
        birthDate: _birth,
        sex: Sex.female,
        countryCode: 'JP',
        manualLifespanYears: 90,
      );
      verify(() => repo.saveProfile(expected)).called(1);
      verify(
        () =>
            repo.saveSettings(AppSettings.defaults.copyWith(tone: ToneId.wit)),
      ).called(1);
      expect(completed.single.$1, expected);
      expect(completed.single.$2.tone, ToneId.wit);
      expect(c.state.step, OnboardingStep.done);
      // 만기 2080-01-01, 오늘 2026-06-15
      expect(
        c.state.firstBalance!.remainingDays,
        _today.daysUntil(const CalendarDate(2080, 1, 1)),
      );
    },
  );

  test('complete 실패 시 saveFailed 오류, done으로 가지 않음', () async {
    when(() => repo.saveProfile(any())).thenThrow(Exception('disk'));
    final c = build()..setBirthDate(_birth);
    await c.complete();
    expect(c.state.error, OnboardingError.saveFailed);
    expect(c.state.step, OnboardingStep.birthDate);
    expect(c.state.saving, isFalse);
    expect(completed, isEmpty);
  });

  test('생년월일 없이 complete는 아무것도 하지 않음', () async {
    await build().complete();
    verifyNever(() => repo.saveProfile(any()));
  });

  group('알림 권한', () {
    test('거부되면 상시 알림 설정을 끔', () async {
      await build().applyNotificationPermission(granted: false);
      verify(
        () => repo.saveSettings(
          AppSettings.defaults.copyWith(ongoingNotification: false),
        ),
      ).called(1);
    });
    test('허용되면 설정 변경 없음', () async {
      await build().applyNotificationPermission(granted: true);
      verifyNever(() => repo.saveSettings(any()));
    });
  });
}
