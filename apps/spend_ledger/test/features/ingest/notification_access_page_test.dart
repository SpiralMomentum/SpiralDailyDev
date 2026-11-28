import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spend_ledger/features/ingest/data/android_bridge.dart';
import 'package:spend_ledger/features/ingest/presentation/notification_access_page.dart';
import 'package:spend_ledger/features/settings/presentation/settings_cubit.dart';

import '../../support/fakes.dart';

class _MockBridge extends Mock implements AndroidBridge {}

void main() {
  testWidgets('shows off, opens settings, rechecks on resume', (tester) async {
    final bridge = _MockBridge();
    var enabled = false;
    when(() => bridge.listenerEnabled()).thenAnswer((_) async => enabled);
    when(() => bridge.openListenerSettings()).thenAnswer((_) async {});
    when(() => bridge.setAllowedPackages(any())).thenAnswer((_) async {});
    when(() => bridge.recentPackages()).thenAnswer((_) async => const []);
    late IngestHarness h;
    late SettingsCubit cubit;
    await tester.runAsync(() async {
      h = await openHarness();
      cubit = SettingsCubit(h.deps.settings, () async {}, bridge: bridge);
      await cubit.load();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: NotificationAccessPage(bridge: bridge),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('꺼짐'), findsOneWidget);
    expect(find.text('수집할 앱'), findsOneWidget);

    await tester.tap(find.text('알림 접근 설정 열기'));
    await tester.pump();
    verify(() => bridge.openListenerSettings()).called(1);

    enabled = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('켜짐'), findsOneWidget);

    await tester.runAsync(() async {
      await cubit.close();
      await h.close();
    });
  });
}
