import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/life_table/data/life_table_parser.dart';
import 'package:life_balance/features/ongoing_notification/data/ongoing_notifier.dart';
import 'package:life_balance/features/profile/domain/profile_repository.dart';
import 'package:life_balance/features/profile/domain/settings.dart';
import 'package:life_balance/features/profile/presentation/onboarding/onboarding_cubit.dart';
import 'package:life_balance/features/profile/presentation/onboarding/onboarding_page.dart';
import 'package:life_balance/features/profile/presentation/onboarding/widget_pinner.dart';
import 'package:life_balance/features/tone/domain/tone.dart';
import 'package:life_balance/features/tone/domain/tone_table.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_life_table.dart';

class MockRepo extends Mock implements ProfileRepository {}

class FakePinner implements WidgetPinner {
  FakePinner(this.supported);
  final bool supported;
  int pinCalls = 0;
  @override
  Future<bool> isSupported() async => supported;
  @override
  Future<void> requestPin() async => pinCalls++;
}

class FakeNotifier implements OngoingNotifier {
  FakeNotifier(this.granted);
  final bool granted;
  int calls = 0;
  @override
  Future<bool> requestPermission() async {
    calls++;
    return granted;
  }

  @override
  Future<void> show(String text) async {}
  @override
  Future<void> cancel() async {}
}

const _today = CalendarDate(2026, 6, 15);

ToneTable _tone(ToneId id) => ToneTable(
  id: id,
  phrases: const {
    'onboarding.intro': ['소개 문구'],
    'onboarding.widget_guide': ['홈 화면을 길게 눌러 위젯을 추가하세요'],
  },
);

void main() {
  late MockRepo repo;
  late OnboardingCubit cubit;

  setUpAll(() {
    registerFallbackValue(
      const Profile(
        birthDate: CalendarDate(1990, 1, 1),
        sex: Sex.male,
        countryCode: 'KR',
      ),
    );
    registerFallbackValue(AppSettings.defaults);
  });

  OnboardingCubit makeCubit({bool granted = true}) => OnboardingCubit(
    repo: repo,
    notifier: FakeNotifier(granted),
    table: FakeLifeTable({for (var a = 0; a <= 150; a++) a: 40.0}),
    today: () => _today,
    deviceCountry: 'KR',
    onComplete: (_, _) async {},
  );

  setUp(() {
    repo = MockRepo();
    when(() => repo.saveProfile(any())).thenAnswer((_) async {});
    when(() => repo.saveSettings(any())).thenAnswer((_) async {});
    when(
      () => repo.loadSettings(),
    ).thenAnswer((_) async => AppSettings.defaults);
    cubit = makeCubit();
  });

  tearDown(() => cubit.close());

  Widget app({WidgetPinner? pinner}) => MaterialApp(
    home: OnboardingPage(
      cubit: cubit,
      countries: const [
        CountryInfo(
          code: 'KR',
          name: '대한민국',
          sourceName: 'WHO',
          sourceYear: 2021,
        ),
      ],
      tones: {for (final t in ToneId.values) t: _tone(t)},
      today: () => _today,
      pinner: pinner ?? FakePinner(true),
    ),
  );

  Future<void> tapText(WidgetTester t, String text) async {
    await t.tap(find.text(text));
    await t.pumpAndSettle();
  }

  testWidgets('5단계 진행 후 첫 잔고 숫자와 위젯 추가 버튼 표시', (t) async {
    final pinner = FakePinner(true);
    await t.pumpWidget(app(pinner: pinner));

    expect(find.text('소개 문구'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);
    expect(t.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);

    cubit.setBirthDate(const CalendarDate(1990, 1, 1));
    await t.pumpAndSettle();
    await tapText(t, '다음');

    expect(find.text('생명표 기준 성별'), findsOneWidget);
    await tapText(t, '여성');
    await tapText(t, '다음');

    expect(find.text('대한민국'), findsOneWidget);
    await tapText(t, '다음');

    expect(find.text('생명표 추정 기대수명 76.0세'), findsOneWidget);
    await t.enterText(find.byType(TextField), '90');
    await t.pumpAndSettle();
    await tapText(t, '다음');

    await tapText(t, '재치 있는 농담');
    await tapText(t, '시작하기');

    // 만기 1990+90 = 2080-01-01
    final days = _today.daysUntil(const CalendarDate(2080, 1, 1));
    final grouped = days.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
    expect(find.text('$grouped일'), findsOneWidget);

    await tapText(t, '홈 화면에 위젯 추가');
    expect(pinner.pinCalls, 1);

    expect(find.textContaining('알림 권한이 없어'), findsNothing);
  });

  testWidgets('위젯 핀 미지원이면 톤 안내 문구 표시', (t) async {
    await t.pumpWidget(app(pinner: FakePinner(false)));
    cubit.setBirthDate(const CalendarDate(1990, 1, 1));
    await cubit.complete();
    await t.pumpAndSettle();
    expect(find.text('홈 화면을 길게 눌러 위젯을 추가하세요'), findsOneWidget);
    expect(find.text('홈 화면에 위젯 추가'), findsNothing);
  });

  testWidgets('알림 거부 시 안내 문구와 설정 끔 저장', (t) async {
    cubit = makeCubit(granted: false);
    await t.pumpWidget(app());
    cubit.setBirthDate(const CalendarDate(1990, 1, 1));
    await cubit.complete();
    await t.pumpAndSettle();
    expect(find.textContaining('알림 권한이 없어'), findsOneWidget);
    verify(
      () => repo.saveSettings(
        AppSettings.defaults.copyWith(ongoingNotification: false),
      ),
    ).called(1);
  });

  testWidgets('잘못된 기대수명 입력 시 오류 문구', (t) async {
    await t.pumpWidget(app());
    cubit.setBirthDate(const CalendarDate(1990, 1, 1));
    cubit
      ..next()
      ..next()
      ..next();
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), '200');
    await t.pumpAndSettle();
    expect(find.text('0보다 크고 150 이하인 숫자를 입력하세요.'), findsOneWidget);
    final next = find.widgetWithText(FilledButton, '다음');
    expect(t.widget<FilledButton>(next).onPressed, isNull);
    await t.enterText(find.byType(TextField), '20');
    await t.pumpAndSettle();
    expect(t.widget<FilledButton>(next).onPressed, isNotNull);
  });
}
