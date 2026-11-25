import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/life_table/data/life_table_parser.dart';
import 'package:life_balance/features/ongoing_notification/data/ongoing_notifier.dart';
import 'package:life_balance/features/profile/domain/profile_repository.dart';
import 'package:life_balance/features/profile/domain/settings.dart';
import 'package:life_balance/features/profile/presentation/onboarding/widget_pinner.dart';
import 'package:life_balance/features/settings/presentation/settings_cubit.dart';
import 'package:life_balance/features/settings/presentation/settings_page.dart';
import 'package:life_balance/features/tone/domain/tone.dart';
import 'package:life_balance/features/tone/domain/tone_table.dart';
import 'package:mocktail/mocktail.dart';

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
  @override
  Future<bool> requestPermission() async => granted;
  @override
  Future<void> show(String text) async {}
  @override
  Future<void> cancel() async {}
}

const _profile = Profile(
  birthDate: CalendarDate(1990, 1, 1),
  sex: Sex.male,
  countryCode: 'KR',
  manualLifespanYears: 90,
);

const _countries = [
  CountryInfo(
    code: 'KR',
    name: '대한민국',
    sourceName: '통계청 생명표',
    sourceYear: 2023,
  ),
  CountryInfo(code: 'JP', name: '일본', sourceName: '후생노동성', sourceYear: 2022),
];

final _tones = {
  for (final t in ToneId.values)
    t: ToneTable(
      id: t,
      phrases: const {
        'onboarding.widget_guide': ['홈 화면을 길게 눌러 위젯을 추가하세요'],
      },
    ),
};

void main() {
  late MockRepo repo;
  late List<(Profile, AppSettings)> changes;

  setUpAll(() {
    registerFallbackValue(_profile);
    registerFallbackValue(AppSettings.defaults);
  });

  setUp(() {
    repo = MockRepo();
    changes = [];
    when(() => repo.saveProfile(any())).thenAnswer((_) async {});
    when(() => repo.saveSettings(any())).thenAnswer((_) async {});
  });

  Future<SettingsCubit> pump(
    WidgetTester tester, {
    bool granted = true,
    bool pinSupported = true,
    FakePinner? pinner,
    AppSettings settings = AppSettings.defaults,
    Profile profile = _profile,
  }) async {
    final cubit = SettingsCubit(
      repo: repo,
      notifier: FakeNotifier(granted),
      today: () => const CalendarDate(2026, 6, 15),
      initialProfile: profile,
      initialSettings: settings,
      onChanged: (p, s) async => changes.add((p, s)),
    );
    addTearDown(cubit.close);
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsPage(
                  cubit: cubit,
                  countries: _countries,
                  tones: _tones,
                  today: () => const CalendarDate(2026, 6, 15),
                  pinner: pinner ?? FakePinner(pinSupported),
                ),
              ),
            ),
            child: const Text('열기'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('shows sources per country and has back button', (tester) async {
    await pump(tester);
    expect(find.textContaining('통계청 생명표 2023'), findsOneWidget);
    expect(find.textContaining('후생노동성 2022'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('tapping unit option saves and notifies', (tester) async {
    await pump(tester);
    await tester.tap(find.text('주'));
    await tester.pumpAndSettle();
    expect(changes.single.$2.unit.name, 'weeks');
  });

  testWidgets('tone option change notifies', (tester) async {
    await pump(tester);
    await tester.tap(find.text('재치 있는 농담'));
    await tester.pumpAndSettle();
    expect(changes.single.$2.tone, ToneId.wit);
  });

  testWidgets('switching manual lifespan to auto clears it', (tester) async {
    final cubit = await pump(tester);
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.byKey(const Key('lifespan-manual-switch')));
    await tester.pumpAndSettle();
    expect(cubit.state.profile.manualLifespanYears, isNull);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('invalid manual lifespan shows error and is not saved',
      (tester) async {
    final cubit = await pump(tester);
    await tester.enterText(find.byType(TextField), '999');
    await tester.pumpAndSettle();
    expect(find.text('0보다 크고 150 이하인 숫자를 입력하세요.'), findsOneWidget);
    expect(cubit.state.profile.manualLifespanYears, 90);
    expect(changes, isEmpty);
  });

  testWidgets('valid manual lifespan saves', (tester) async {
    final cubit = await pump(tester);
    await tester.enterText(find.byType(TextField), '85.5');
    await tester.pumpAndSettle();
    expect(cubit.state.profile.manualLifespanYears, 85.5);
  });

  testWidgets('permission denied: switch stays off and message shown',
      (tester) async {
    await pump(
      tester,
      granted: false,
      settings: AppSettings.defaults.copyWith(ongoingNotification: false),
    );
    await tester.tap(find.byKey(const Key('ongoing-switch')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byKey(const Key('ongoing-switch'))).value,
      isFalse,
    );
    expect(find.textContaining('알림 권한'), findsOneWidget);
  });

  testWidgets('widget guide button requests pin when supported',
      (tester) async {
    final pinner = FakePinner(true);
    await pump(tester, pinner: pinner);
    await tester.tap(find.text('위젯 추가 안내 다시 보기'));
    await tester.pumpAndSettle();
    expect(pinner.pinCalls, 1);
  });

  testWidgets('widget guide shows tone phrase when pin unsupported',
      (tester) async {
    await pump(tester, pinSupported: false);
    await tester.tap(find.text('위젯 추가 안내 다시 보기'));
    await tester.pumpAndSettle();
    expect(find.text('홈 화면을 길게 눌러 위젯을 추가하세요'), findsOneWidget);
  });

  testWidgets('license entry opens license page', (tester) async {
    await pump(tester);
    await tester.tap(find.text('오픈소스 라이선스'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
