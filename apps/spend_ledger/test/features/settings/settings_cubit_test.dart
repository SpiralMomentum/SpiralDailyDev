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
