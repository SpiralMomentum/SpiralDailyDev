import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/app/app_config.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/balance/presentation/passbook_cubit.dart';
import 'package:life_balance/features/balance/presentation/passbook_page.dart';
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
    'kairos.intro': ['카이로스 소개'],
    'kairos.cta': ['출시 알림 받기'],
  },
);

Future<PassbookCubit> pump(
  WidgetTester t, {
  double? manual,
  VoidCallback? onSettings,
  AppConfig config = const AppConfig(),
}) async {
  final cubit = PassbookCubit(
    profile: Profile(
      birthDate: const CalendarDate(2000, 1, 1),
      sex: Sex.male,
      countryCode: 'KR',
      manualLifespanYears: manual,
    ),
    settings: AppSettings.defaults,
    table: FakeLifeTable({for (var a = 0; a <= 150; a++) a: 53.0}),
    tone: tone,
    today: () => const CalendarDate(2026, 1, 1),
  );
  await t.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: PassbookPage(
          config: config,
          tone: tone,
          onOpenSettings: onSettings ?? () {},
        ),
      ),
    ),
  );
  return cubit;
}

void main() {
  testWidgets('shows balance, dates, withdrawal once and kairos card', (
    t,
  ) async {
    await pump(t);
    expect(find.text('19,358일'), findsOneWidget);
    expect(find.text('2000.01.01'), findsOneWidget);
    expect(find.text('2079.01.01'), findsOneWidget);
    expect(find.text('계좌 개설일'), findsOneWidget);
    expect(find.text('오늘 출금 -1일'), findsOneWidget);
    expect(find.textContaining('-1일 -1일'), findsNothing);
    expect(find.text('카이로스 소개'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('bonus shows notice and hides withdrawal', (t) async {
    await pump(t, manual: 20);
    expect(find.textContaining('덤 +'), findsOneWidget);
    expect(find.text('오늘 출금 -1일'), findsNothing);
    final bar = t.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 1.0);
  });

  testWidgets('settings icon calls callback', (t) async {
    var n = 0;
    await pump(t, onSettings: () => n++);
    await t.tap(find.byIcon(Icons.settings_outlined));
    expect(n, 1);
  });
}
