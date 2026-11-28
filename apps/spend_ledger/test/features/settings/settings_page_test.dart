import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/budget/domain/budget_alert.dart';
import 'package:spend_ledger/features/ingest/domain/ingest.dart';
import 'package:spend_ledger/features/settings/domain/app_settings.dart';
import 'package:spend_ledger/features/settings/domain/settings_repository.dart';
import 'package:spend_ledger/features/settings/presentation/settings_cubit.dart';
import 'package:spend_ledger/features/settings/presentation/settings_page.dart';
import 'package:spend_ledger/features/settings/presentation/theme_page.dart';

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

  Future<void> wait(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }

  Future<(IngestHarness, _FlakyRepo, SettingsCubit)> showFailing(
    WidgetTester tester,
    Widget page,
  ) async {
    late IngestHarness h;
    await tester.runAsync(
      () async =>
          h = await openHarness(settings: const AppSettings(budget: 500000)),
    );
    final repo = _FlakyRepo(h.deps.settings);
    final cubit = SettingsCubit(repo, () async {});
    await tester.pumpWidget(
      RepositoryProvider<IngestDeps>.value(
        value: h.deps,
        child: BlocProvider.value(
          value: cubit,
          child: MaterialApp(home: page),
        ),
      ),
    );
    await wait(tester);
    return (h, repo, cubit);
  }

  testWidgets('설정 읽기 실패면 목록 대신 오류와 다시 시도를 보여 준다', (tester) async {
    final (h, repo, cubit) = await showFailing(tester, const SettingsPage());
    expect(find.text('설정을 불러오지 못했어요'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.text('월 예산'), findsNothing);

    // 다시 시도가 또 실패해도 오류 화면이 남는다.
    await tester.tap(find.text('다시 시도'));
    await wait(tester);
    expect(find.text('설정을 불러오지 못했어요'), findsOneWidget);
    expect(repo.loads, 2);

    repo.failLoad = false;
    await tester.tap(find.text('다시 시도'));
    await wait(tester);
    await tester.pumpAndSettle();
    expect(find.text('설정을 불러오지 못했어요'), findsNothing);
    expect(find.text('월 예산'), findsOneWidget);
    expect(find.text('500,000원'), findsOneWidget);
    expect(repo.saves, 0);
    await tester.runAsync(() async {
      await cubit.close();
      await h.close();
    });
  });

  testWidgets('테마 화면도 읽기 실패면 오류와 다시 시도를 보여 준다', (tester) async {
    final (h, repo, cubit) = await showFailing(tester, const ThemePage());
    // ThemePage는 스스로 읽지 않으므로 앱 시작 때의 읽기를 흉내 낸다.
    await tester.runAsync(cubit.load);
    await tester.pump();
    expect(find.text('설정을 불러오지 못했어요'), findsOneWidget);
    expect(find.text('베이지'), findsNothing);

    repo.failLoad = false;
    await tester.tap(find.text('다시 시도'));
    await wait(tester);
    expect(find.text('베이지'), findsOneWidget);
    await tester.runAsync(() async {
      await cubit.close();
      await h.close();
    });
  });
}

class _FlakyRepo implements SettingsRepository {
  _FlakyRepo(this.inner);
  final SettingsRepository inner;
  bool failLoad = true;
  int loads = 0;
  int saves = 0;

  @override
  Future<AppSettings> load() async {
    loads++;
    if (failLoad) throw const FormatException('bad');
    return inner.load();
  }

  @override
  Future<void> save(AppSettings s) {
    saves++;
    return inner.save(s);
  }

  @override
  Future<Set<BudgetAlert>> sentAlerts(String periodKey) =>
      inner.sentAlerts(periodKey);

  @override
  Future<bool> markSent(String periodKey, BudgetAlert a) =>
      inner.markSent(periodKey, a);
}
