import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/app/bootstrap.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/profile/data/prefs_profile_repository.dart';
import 'package:life_balance/features/profile/domain/settings.dart';
import 'package:life_balance/features/tone/domain/tone.dart';
import 'package:life_balance/features/tone/presentation/tone_theme.dart';

import '../helpers/app_harness.dart';

const _profile = Profile(
  birthDate: CalendarDate(1990, 1, 1),
  sex: Sex.male,
  countryCode: 'KR',
);

String _balanceText(WidgetTester t) =>
    t.widget<Text>(find.byKey(const Key('balance'))).data!;

MaterialApp _materialApp(WidgetTester t) =>
    t.widget<MaterialApp>(find.byType(MaterialApp));

void main() {
  late Harness h;

  setUp(() => h = Harness());

  /// 설정 ListView에서 [f]가 보일 때까지 스크롤한 뒤 누른다.
  Future<void> scrollTap(WidgetTester t, Finder f, {double delta = 150}) async {
    await t.scrollUntilVisible(
      f,
      delta,
      scrollable: find.byType(Scrollable).last,
    );
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> start(WidgetTester t) async {
    await t.pumpWidget(await startApp());
    await t.pumpAndSettle();
  }

  testWidgets('프로필이 없으면 온보딩 첫 화면, 동기화/예약 없음', (t) async {
    await h.setUp();
    await start(t);

    expect(find.text('1 / 5'), findsOneWidget);
    expect(find.text('생년월일 선택'), findsOneWidget);
    expect(find.byKey(const Key('balance')), findsNothing);
    expect(h.background.calls, 1);
    expect(h.gateway.saves, isEmpty);
    expect(h.scheduler.calls, isEmpty);
  });

  testWidgets('프로필이 있으면 통장 화면, 시작 시 위젯/알림 동기화와 예약', (t) async {
    await h.setUp(profile: _profile);
    await start(t);

    expect(find.byKey(const Key('balance')), findsOneWidget);
    expect(find.text('1 / 5'), findsNothing);
    expect(h.background.calls, 1);
    expect(h.gateway.saves, hasLength(1));
    expect(h.notifier.shown, hasLength(1));
    expect(h.notifier.shown.single, contains('-1일'));
    expect(h.scheduler.calls, [h.now]);
  });

  testWidgets('생명표 에셋을 못 읽으면 오류 화면', (t) async {
    await h.setUp(profile: _profile, lifeTableAvailable: false);
    await start(t);

    expect(find.text('데이터를 불러오지 못했습니다'), findsOneWidget);
    expect(find.byKey(const Key('balance')), findsNothing);
  });

  testWidgets('생명표가 깨져 있으면 오류 화면', (t) async {
    await h.setUp(profile: _profile, lifeTable: '{}');
    await start(t);

    expect(find.text('데이터를 불러오지 못했습니다'), findsOneWidget);
  });

  testWidgets('말투 에셋을 못 읽으면 오류 화면', (t) async {
    await h.setUp(tonesAvailable: false);
    await start(t);

    expect(find.text('데이터를 불러오지 못했습니다'), findsOneWidget);
  });

  testWidgets('resumed 시 통장 새로고침과 위젯/알림 재동기화', (t) async {
    await h.setUp(profile: _profile);
    await start(t);
    final before = _balanceText(t);

    h.now = h.now.add(const Duration(days: 1));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pumpAndSettle();

    expect(_balanceText(t), isNot(before));
    expect(h.gateway.saves, hasLength(2));
    expect(h.notifier.shown, hasLength(2));
  });

  testWidgets('설정에서 말투/화면 모드를 바꾸면 테마와 통장, 위젯이 즉시 바뀐다', (t) async {
    await h.setUp(profile: _profile);
    await start(t);
    expect(
      _materialApp(t).theme!.colorScheme.primary,
      paletteFor(ToneId.stoic, Brightness.light).accent,
    );

    await t.tap(find.byTooltip('설정'));
    await t.pumpAndSettle();
    expect(find.text('설정'), findsOneWidget);

    await scrollTap(t, find.text('재치 있는 농담'));

    expect(
      _materialApp(t).theme!.colorScheme.primary,
      paletteFor(ToneId.wit, Brightness.light).accent,
    );
    expect(h.gateway.saves, hasLength(2));
    final saved = await PrefsProfileRepository(h.prefs).loadSettings();
    expect(saved.tone, ToneId.wit);

    await scrollTap(t, find.text('다크'));
    expect(_materialApp(t).themeMode, ThemeMode.dark);

    await scrollTap(t, find.text('주'), delta: -150);

    await t.tap(find.byType(BackButton));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('balance')), findsOneWidget);
    expect(_balanceText(t), endsWith('주'));
  });

  testWidgets('상시 알림을 끄면 알림이 취소된다', (t) async {
    await h.setUp(profile: _profile);
    await start(t);
    await t.tap(find.byTooltip('설정'));
    await t.pumpAndSettle();

    await scrollTap(t, find.byKey(const Key('ongoing-switch')));

    expect(h.notifier.cancels, 1);
    final saved = await PrefsProfileRepository(h.prefs).loadSettings();
    expect(saved.ongoingNotification, isFalse);
  });

  testWidgets('온보딩 완료 시 동기화/예약 후 통장 열기로 메인 진입', (t) async {
    await h.setUp();
    await start(t);

    await t.tap(find.text('생년월일 선택'));
    await t.pumpAndSettle();
    await t.tap(find.text('확인'));
    await t.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await t.tap(find.text('다음'));
      await t.pumpAndSettle();
    }
    await t.tap(find.text('커뮤니티 말투'));
    await t.pumpAndSettle();
    await t.tap(find.text('시작하기'));
    await t.pumpAndSettle();

    expect(h.gateway.saves, hasLength(1));
    expect(h.scheduler.calls, hasLength(1));
    final profile = await PrefsProfileRepository(h.prefs).loadProfile();
    expect(profile, isNotNull);

    await t.tap(find.text('통장 열기'));
    await t.pumpAndSettle();

    expect(find.byKey(const Key('balance')), findsOneWidget);
    expect(
      _materialApp(t).theme!.colorScheme.primary,
      paletteFor(ToneId.community, Brightness.light).accent,
    );
  });

  testWidgets('저장된 설정의 테마 선호를 따른다', (t) async {
    await h.setUp(
      profile: _profile,
      settings: AppSettings.defaults.copyWith(themePref: ThemePref.light),
    );
    await start(t);
    expect(_materialApp(t).themeMode, ThemeMode.light);
  });
}
