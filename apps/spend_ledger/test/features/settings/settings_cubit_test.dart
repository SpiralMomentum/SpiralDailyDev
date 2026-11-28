import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spend_ledger/features/ingest/data/android_bridge.dart';
import 'package:spend_ledger/features/budget/domain/budget_alert.dart';
import 'package:spend_ledger/features/message_filter/domain/filter_rule.dart';
import 'package:spend_ledger/features/message_filter/domain/name_registry.dart';
import 'package:spend_ledger/features/settings/domain/app_settings.dart';
import 'package:spend_ledger/features/theme/domain/palette.dart';
import 'package:spend_ledger/features/settings/domain/settings_repository.dart';
import 'package:spend_ledger/features/settings/presentation/filters_page.dart';
import 'package:spend_ledger/features/settings/presentation/names_page.dart';
import 'package:spend_ledger/features/settings/presentation/settings_cubit.dart';

import '../../support/fakes.dart';

void main() {
  group('읽기 실패', flakyTests);
  late IngestHarness h;
  late int refreshes;
  late SettingsCubit cubit;

  setUp(() async {
    h = await openHarness();
    refreshes = 0;
    cubit = SettingsCubit(h.deps.settings, () async => refreshes++);
    await cubit.load();
  });
  tearDown(() async {
    await cubit.close();
    await h.close();
  });

  test('start day out of range ignored', () async {
    await cubit.setStartDay(0);
    await cubit.setStartDay(32);
    expect(cubit.state.settings.startDay, 1);
    expect(refreshes, 0);
    await cubit.setStartDay(25);
    expect(cubit.state.settings.startDay, 25);
    expect((await h.deps.settings.load()).startDay, 25);
    expect(refreshes, 1);
  });

  test('setTheme은 저장 후 refresh를 부른다', () async {
    await cubit.setTheme(AppThemeId.beige);
    expect((await h.deps.settings.load()).themeId, AppThemeId.beige);
    expect(refreshes, 1);
    expect(cubit.state.settings.themeId, AppThemeId.beige);
  });

  test('setThemeMode는 저장 후 refresh를 부른다', () async {
    await cubit.setThemeMode(AppThemeMode.dark);
    expect((await h.deps.settings.load()).themeMode, AppThemeMode.dark);
    expect(refreshes, 1);
    expect(cubit.state.settings.themeMode, AppThemeMode.dark);
  });

  test('budget set and cleared', () async {
    await cubit.setBudget(500000);
    expect((await h.deps.settings.load()).budget, 500000);
    await cubit.setBudget(null);
    expect((await h.deps.settings.load()).budget, isNull);
    expect(refreshes, 2);
  });

  test('saving names triggers refresh', () async {
    const names = NameRegistry(
      selfNames: ['홍길동'],
      chargeTargets: ['쿠팡페이'],
      prepaidMoneys: [],
    );
    await cubit.saveNames(names);
    expect((await h.deps.settings.load()).names, names);
    expect(refreshes, 1);
  });

  test('toggles and filters persist', () async {
    await cubit.setDeleteRawText(false);
    await cubit.setHideAmounts(true);
    await cubit.saveFilters(const [FilterRule(senderPattern: 'KB')]);
    final saved = await h.deps.settings.load();
    expect(saved.deleteRawText, isFalse);
    expect(saved.hideAmounts, isTrue);
    expect(saved.filters, const [FilterRule(senderPattern: 'KB')]);
    await cubit.saveFilters(defaultFilterRules);
    expect((await h.deps.settings.load()).filters, defaultFilterRules);
  });

  test('save failure keeps previous value and reports error', () async {
    final failing = SettingsCubit(_FailingSave(h.deps.settings), () async {});
    await failing.load();
    await failing.setBudget(1000);
    expect(failing.state.settings.budget, isNull);
    expect(failing.state.error, isNotNull);
    await failing.close();
  });

  test('refresh failure keeps saved value', () async {
    final c = SettingsCubit(h.deps.settings, () async => throw StateError('x'));
    await c.load();
    await c.setBudget(1000);
    expect(c.state.settings.budget, 1000);
    expect(c.state.error, isNull);
    await c.close();
  });

  bridgeTests();

  test('helpers trim and ignore empty', () {
    expect(splitKeywords(' 승인, ,결제 ,'), ['승인', '결제']);
    expect(addName(['가나'], '  '), ['가나']);
    expect(addName(['가나'], ' 다라 '), ['가나', '다라']);
    expect(addName(['가나'], '가나'), ['가나']);
    expect(addName(['가나'], ' 다 '), ['가나']);
    expect(isNameTooShort(' 다 '), isTrue);
    expect(isNameTooShort('다라'), isFalse);
  });
}

class _FailingSave implements SettingsRepository {
  _FailingSave(this._inner);
  final SettingsRepository _inner;
  @override
  Future<AppSettings> load() => _inner.load();
  @override
  Future<void> save(AppSettings s) => throw StateError('save failed');
  @override
  Future<Set<BudgetAlert>> sentAlerts(String k) => _inner.sentAlerts(k);
  @override
  Future<bool> markSent(String k, BudgetAlert a) => _inner.markSent(k, a);
}

class MockAndroidBridge extends Mock implements AndroidBridge {}

void bridgeTests() {
  test('setNotificationPackages saves and pushes to the bridge', () async {
    final h = await openHarness();
    final bridge = MockAndroidBridge();
    when(() => bridge.setAllowedPackages(any())).thenAnswer((_) async {});
    final c = SettingsCubit(h.deps.settings, () async {}, bridge: bridge);
    await c.load();
    await c.setNotificationPackages(['a.b']);
    expect((await h.deps.settings.load()).notificationPackages, ['a.b']);
    verify(() => bridge.setAllowedPackages(['a.b'])).called(1);
    await c.close();
    await h.close();
  });
}

class _FlakyRepo implements SettingsRepository {
  _FlakyRepo(this.inner);
  final SettingsRepository inner;
  bool failLoad = true;
  int saves = 0;

  @override
  Future<AppSettings> load() async {
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

void flakyTests() {
  late IngestHarness h;
  late _FlakyRepo repo;

  setUp(() async {
    h = await openHarness(settings: const AppSettings(budget: 500000));
    repo = _FlakyRepo(h.deps.settings);
  });
  tearDown(() => h.close());

  test('읽기 실패 뒤 setTheme은 저장하지 않고 오류를 낸다', () async {
    final cubit = SettingsCubit(repo, () async {}, initial: null);
    await runZonedGuarded(() async {
      await cubit.load();
      await cubit.setTheme(AppThemeId.beige);
    }, (_, _) {});
    expect(repo.saves, 0);
    expect(cubit.state.error, isNotNull);
    expect((await h.deps.settings.load()).budget, 500000);
    await cubit.close();
  });

  test('읽기 실패 뒤 다시 읽는 동안 loading이 켜졌다가 오류로 돌아온다', () async {
    final cubit = SettingsCubit(repo, () async {});
    final states = <SettingsState>[];
    final sub = cubit.stream.listen(states.add);
    await runZonedGuarded(() async {
      await cubit.load();
      await cubit.load();
    }, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(states.map((s) => (s.loading, s.loaded, s.error != null)), [
      (false, false, true),
      (true, false, false),
      (false, false, true),
    ]);
    await sub.cancel();
    await cubit.close();
  });

  test('읽는 중에 닫혀도 emit하지 않는다', () async {
    repo.failLoad = false;
    final cubit = SettingsCubit(repo, () async {});
    final pending = cubit.load();
    await cubit.close();
    await pending;
    expect(cubit.isClosed, isTrue);
  });

  test('저장 중에 닫혀도 emit하지 않는다', () async {
    repo.failLoad = false;
    final cubit = SettingsCubit(repo, () async {});
    await cubit.load();
    final pending = cubit.setTheme(AppThemeId.beige);
    await cubit.close();
    await pending;
    expect((await h.deps.settings.load()).themeId, AppThemeId.beige);
  });

  test('읽기 실패 뒤 load가 성공하면 실제 설정 위에 저장한다', () async {
    final cubit = SettingsCubit(repo, () async {});
    await runZonedGuarded(cubit.load, (_, _) {});
    repo.failLoad = false;
    await cubit.setTheme(AppThemeId.beige);
    final saved = await h.deps.settings.load();
    expect(saved.themeId, AppThemeId.beige);
    expect(saved.budget, 500000);
    await cubit.close();
  });
}
