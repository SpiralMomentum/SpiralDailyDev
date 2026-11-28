import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spend_ledger/features/ingest/data/android_bridge.dart';
import 'package:spend_ledger/features/settings/presentation/allowed_apps_page.dart';
import 'package:spend_ledger/features/settings/presentation/settings_cubit.dart';

import '../../support/fakes.dart';

class _MockBridge extends Mock implements AndroidBridge {}

void main() {
  late _MockBridge bridge;
  late IngestHarness h;
  late SettingsCubit cubit;

  Future<void> open(WidgetTester tester) async {
    bridge = _MockBridge();
    when(() => bridge.setAllowedPackages(any())).thenAnswer((_) async {});
    when(() => bridge.recentPackages()).thenAnswer(
      (_) async => const [
        RecentPackage(package: 'com.samsung.android.messaging', label: 'x'),
        RecentPackage(package: 'com.kb.card', label: 'KB Pay'),
      ],
    );
    await tester.runAsync(() async {
      h = await openHarness();
      cubit = SettingsCubit(h.deps.settings, () async {}, bridge: bridge);
      await cubit.load();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: AllowedAppsPage(bridge: bridge),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) => tester.runAsync(() async {
    await cubit.close();
    await h.close();
  });

  testWidgets('shows defaults, hides allowed apps from recents, adds', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('삼성 메시지'), findsOneWidget);
    expect(find.text('Google 메시지'), findsOneWidget);
    expect(find.text('KB Pay'), findsOneWidget);
    expect(find.text('x'), findsNothing);

    await tester.tap(find.text('KB Pay'));
    await settle(tester);
    expect(cubit.state.settings.notificationPackages, [
      'com.samsung.android.messaging',
      'com.google.android.apps.messaging',
      'com.kb.card',
    ]);
    expect(find.text('KB Pay'), findsOneWidget);
    expect(find.byTooltip('삭제'), findsNWidgets(3));
    await close(tester);
  });

  testWidgets('manual package add', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), ' com.my.app ');
    await tester.tap(find.byTooltip('추가'));
    await settle(tester);
    expect(cubit.state.settings.notificationPackages, contains('com.my.app'));
    expect(find.text('com.my.app'), findsOneWidget);
    await close(tester);
  });

  testWidgets('removing all shows warning and calls cubit', (tester) async {
    await open(tester);
    expect(find.text('수집할 앱이 없어 결제 알림을 받지 않습니다.'), findsNothing);
    await tester.tap(find.byTooltip('삭제').first);
    await settle(tester);
    await tester.tap(find.byTooltip('삭제').first);
    await settle(tester);
    expect(cubit.state.settings.notificationPackages, isEmpty);
    verify(() => bridge.setAllowedPackages(const [])).called(1);
    expect(find.text('수집할 앱이 없어 결제 알림을 받지 않습니다.'), findsOneWidget);
    await close(tester);
  });
}
