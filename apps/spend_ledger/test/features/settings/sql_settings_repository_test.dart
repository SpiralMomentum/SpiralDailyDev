import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/budget/domain/budget_alert.dart';
import 'package:spend_ledger/features/message_filter/domain/filter_rule.dart';
import 'package:spend_ledger/features/message_filter/domain/name_registry.dart';
import 'package:spend_ledger/features/settings/data/sql_settings_repository.dart';
import 'package:spend_ledger/features/settings/domain/app_settings.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../support/memory_db.dart';

void main() {
  late Database db;
  late SqlSettingsRepository repo;
  setUp(() async {
    db = await openMemoryDb();
    repo = SqlSettingsRepository(db);
  });
  tearDown(() => db.close());

  test('settings default when empty', () async {
    final s = await repo.load();
    expect(s, const AppSettings());
    expect(s.startDay, 1);
    expect(s.budget, isNull);
    expect(s.deleteRawText, isTrue);
    expect(s.hideAmounts, isFalse);
    expect(s.filters, defaultFilterRules);
  });

  test('settings roundtrip', () async {
    const s = AppSettings(
      startDay: 25,
      budget: 1500000,
      deleteRawText: false,
      hideAmounts: true,
      filters: [
        FilterRule(senderPattern: '1588', includeKeywords: ['승인']),
      ],
      names: NameRegistry(
        selfNames: ['홍길동'],
        chargeTargets: ['카카오페이'],
        prepaidMoneys: ['네이버페이'],
      ),
    );
    await repo.save(s);
    expect(await repo.load(), s);
    await repo.save(s.copyWith(clearBudget: true));
    expect((await repo.load()).budget, isNull);
  });

  test('sent alerts per period', () async {
    expect(await repo.sentAlerts('2026-11'), isEmpty);
    await repo.markSent('2026-11', BudgetAlert.projectedOver);
    await repo.markSent('2026-11', BudgetAlert.projectedOver);
    await repo.markSent('2026-11', BudgetAlert.actualOver);
    await repo.markSent('2026-12', BudgetAlert.actualOver);
    expect(await repo.sentAlerts('2026-11'), {
      BudgetAlert.projectedOver,
      BudgetAlert.actualOver,
    });
    expect(await repo.sentAlerts('2026-12'), {BudgetAlert.actualOver});
  });

  test('markSent is idempotent', () async {
    expect(await repo.markSent('2026-11-01', BudgetAlert.actualOver), isTrue);
    expect(await repo.markSent('2026-11-01', BudgetAlert.actualOver), isFalse);
    expect(
      await repo.markSent('2026-11-01', BudgetAlert.projectedOver),
      isTrue,
    );
    expect(await repo.markSent('2026-12-01', BudgetAlert.actualOver), isTrue);
  });
}
