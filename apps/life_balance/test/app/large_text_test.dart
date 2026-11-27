import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/app/app_config.dart';
import 'package:life_balance/app/bootstrap.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/profile/domain/settings.dart';
import 'package:life_balance/features/tone/domain/tone.dart';

import '../helpers/app_harness.dart';

const _profile = Profile(
  birthDate: CalendarDate(1990, 1, 1),
  sex: Sex.female,
  countryCode: 'KR',
);

const _toneLabels = {
  ToneId.stoic: '절제된 스토아',
  ToneId.wit: '재치 있는 농담',
  ToneId.community: '커뮤니티 말투',
};

/// 360x640dp 소형 화면, 시스템 글꼴 2.0배.
void _largeText(WidgetTester t, Brightness b) {
  t.view.physicalSize = const Size(1080, 1920);
  t.view.devicePixelRatio = 3;
  t.platformDispatcher.textScaleFactorTestValue = 2.0;
  t.platformDispatcher.platformBrightnessTestValue = b;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearAllTestValues);
}

Future<void> _settle(WidgetTester t, String where) async {
  await t.pumpAndSettle();
  expect(t.takeException(), isNull, reason: where);
}

Future<void> _tap(WidgetTester t, Finder f, String where) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await _settle(t, where);
}

void main() {
  for (final tone in ToneId.values) {
    for (final b in Brightness.values) {
      final label = '${tone.name}/${b.name}';
      final pref = b == Brightness.light ? ThemePref.light : ThemePref.dark;

      testWidgets('$label 통장과 설정: 2.0배 글꼴에서 overflow 없음', (t) async {
        _largeText(t, b);
        final h = Harness();
        await h.setUp(
          profile: _profile,
          settings: AppSettings.defaults.copyWith(tone: tone, themePref: pref),
          config: const AppConfig(kairosUrl: 'https://example.com/kairos'),
        );
        await t.pumpWidget(await startApp());
        await _settle(t, '$label passbook');

        final balance = find.byKey(const Key('balance'));
        expect(balance, findsOneWidget);
        expect(MediaQuery.textScalerOf(t.element(balance)).scale(10), 20);
        await t.scrollUntilVisible(find.byType(FilledButton), 200);
        await _settle(t, '$label passbook bottom');

        await t.tap(find.byTooltip('설정'));
        await _settle(t, '$label settings');

        final settingsList = find.byType(Scrollable).last;
        await t.scrollUntilVisible(
          find.text('기대수명'),
          200,
          scrollable: settingsList,
        );
        await _tap(t, find.text('기대수명'), '$label lifespan dialog');
        await _tap(
          t,
          find.byKey(const Key('lifespan-manual-switch')),
          '$label lifespan dialog manual',
        );
        await _tap(t, find.text('취소'), '$label lifespan dialog closed');

        await t.scrollUntilVisible(
          find.text('오픈소스 라이선스'),
          200,
          scrollable: settingsList,
        );
        await _settle(t, '$label settings bottom');
      });

      testWidgets('$label 온보딩 전 단계: 2.0배 글꼴에서 overflow 없음', (t) async {
        _largeText(t, b);
        final h = Harness();
        await h.setUp();
        await t.pumpWidget(await startApp());
        await _settle(t, '$label onboarding birth');

        await _tap(t, find.text('생년월일 선택'), '$label date picker');
        await _tap(t, find.text('확인'), '$label birth picked');
        await _tap(t, find.text('다음'), '$label sex');
        await _tap(t, find.text('여성'), '$label sex picked');
        await _tap(t, find.text('다음'), '$label country');
        await _tap(t, find.text('다음'), '$label lifespan');
        await t.enterText(find.byType(TextField), '200');
        await _settle(t, '$label lifespan error');
        await t.enterText(find.byType(TextField), '');
        await _settle(t, '$label lifespan cleared');
        await _tap(t, find.text('다음'), '$label tone');
        await _tap(t, find.text(_toneLabels[tone]!), '$label tone picked');
        await _tap(t, find.text('시작하기'), '$label done');
        await _tap(t, find.text('통장 열기'), '$label passbook after onboarding');
        expect(find.byKey(const Key('balance')), findsOneWidget);
      });
    }
  }
}
