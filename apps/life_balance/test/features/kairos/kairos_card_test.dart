import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/app/app_config.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/kairos/presentation/kairos_card.dart';
import 'package:life_balance/features/tone/domain/tone.dart';
import 'package:life_balance/features/tone/domain/tone_table.dart';

const tone = ToneTable(
  id: ToneId.stoic,
  phrases: {
    'kairos.intro': ['카이로스 소개'],
    'kairos.cta': ['출시 알림 받기'],
  },
);
const today = CalendarDate(2026, 1, 1);

Widget wrap(AppConfig c, List<Uri> opened) => MaterialApp(
  home: Scaffold(
    body: KairosCard(
      config: c,
      tone: tone,
      today: today,
      opener: (u) async => opened.add(u),
    ),
  ),
);

void main() {
  testWidgets('preLaunch without url shows intro only', (t) async {
    await t.pumpWidget(wrap(const AppConfig(), []));
    expect(find.text('카이로스 소개'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('preLaunch with url shows cta and opens url', (t) async {
    final opened = <Uri>[];
    await t.pumpWidget(
      wrap(const AppConfig(kairosUrl: 'https://example.com/notify'), opened),
    );
    await t.tap(find.text('출시 알림 받기'));
    expect(opened, [Uri.parse('https://example.com/notify')]);
  });

  testWidgets('launched with store url shows same cta', (t) async {
    final opened = <Uri>[];
    await t.pumpWidget(
      wrap(
        const AppConfig(
          kairosStatus: KairosStatus.launched,
          kairosUrl: 'https://play.google.com/store/apps/details?id=x',
        ),
        opened,
      ),
    );
    await t.tap(find.byType(FilledButton));
    expect(opened.single.host, 'play.google.com');
  });

  for (final url in [
    'example.com/notify',
    'javascript:alert(1)',
    'intent://x#Intent;end',
    'mailto:a@b.c',
    '',
  ]) {
    testWidgets('http/https가 아닌 url "$url"이면 버튼을 숨긴다', (t) async {
      await t.pumpWidget(wrap(AppConfig(kairosUrl: url), []));
      expect(find.text('카이로스 소개'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });
  }

  testWidgets('대문자 HTTP 스킴도 허용한다', (t) async {
    await t.pumpWidget(
      wrap(const AppConfig(kairosUrl: 'HTTP://example.com'), []),
    );
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
