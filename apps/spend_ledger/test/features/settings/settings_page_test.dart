import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/ingest/domain/ingest.dart';
import 'package:spend_ledger/features/settings/presentation/settings_cubit.dart';
import 'package:spend_ledger/features/settings/presentation/settings_page.dart';

import '../../support/fakes.dart';

void main() {
  Future<IngestHarness> show(WidgetTester tester, TargetPlatform p) async {
    debugDefaultTargetPlatformOverride = p;
    late IngestHarness h;
    await tester.runAsync(() async => h = await openHarness());
    await tester.pumpWidget(
      RepositoryProvider<IngestDeps>.value(
        value: h.deps,
        child: BlocProvider(
          create: (_) => SettingsCubit(h.deps.settings, () async {})..load(),
          child: const MaterialApp(home: SettingsPage()),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    return h;
  }

  testWidgets('android shows notification setup instead of shortcut', (
    tester,
  ) async {
    final h = await show(tester, TargetPlatform.android);
    await tester.dragUntilVisible(
      find.text('수집 진단'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('알림 수집 설정'), findsOneWidget);
    expect(find.text('단축어 설정 안내'), findsNothing);
    expect(find.text('수집 진단'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
    await tester.runAsync(h.close);
  });

  testWidgets('ios keeps shortcut guide', (tester) async {
    final h = await show(tester, TargetPlatform.iOS);
    await tester.dragUntilVisible(
      find.text('수집 진단'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('단축어 설정 안내'), findsOneWidget);
    expect(find.text('알림 수집 설정'), findsNothing);
    expect(find.text('수집 진단'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
    await tester.runAsync(h.close);
  });
}
