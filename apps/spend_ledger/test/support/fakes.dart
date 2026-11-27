import 'package:spend_ledger/features/budget/domain/budget_alert.dart';
import 'package:spend_ledger/features/budget/domain/summary.dart';
import 'package:spend_ledger/features/ingest/domain/ingest.dart';
import 'package:spend_ledger/features/ledger/data/sql_ledger_repository.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';
import 'package:spend_ledger/features/message_filter/domain/raw_message.dart';
import 'package:spend_ledger/features/parsing/data/sql_format_hint_repository.dart';
import 'package:spend_ledger/features/settings/data/sql_settings_repository.dart';
import 'package:spend_ledger/features/settings/domain/app_settings.dart';
import 'package:sqflite_common/sqlite_api.dart' hide Transaction;

import 'memory_db.dart';

/// 보낸 확인 알림·예산 알림·취소 요청을 기록한다.
class FakeNotifier implements ConfirmNotifier {
  final List<Transaction> asked = [];
  final List<BudgetAlert> alerts = [];
  final List<String> cancelled = [];

  @override
  Future<void> askConfirm(Transaction tx) async => asked.add(tx);

  @override
  Future<void> budgetAlert(BudgetAlert alert, LedgerSummary s) async =>
      alerts.add(alert);

  @override
  Future<void> cancel(String txId) async => cancelled.add(txId);
}

/// 마지막으로 저장된 위젯 항목을 보관한다.
class MemoryWidgetGateway implements WidgetGateway {
  Map<String, String>? last;

  @override
  Future<void> save(Map<String, String> entries) async => last = entries;
}

/// 수동으로 진행시키는 시계.
class TestClock {
  TestClock(this.value);

  DateTime value;

  DateTime call() => value;

  void advance([Duration d = const Duration(minutes: 1)]) =>
      value = value.add(d);
}

/// 메모리 DB 위에 만든 [IngestDeps]와 관찰용 가짜들.
class IngestHarness {
  IngestHarness._(this.db, this.deps, this.notifier, this.widgets, this.clock);

  final Database db;
  final IngestDeps deps;
  final FakeNotifier notifier;
  final MemoryWidgetGateway widgets;
  final TestClock clock;

  /// 현재 시각에 받은 문자. 다음 문자를 위해 시계를 1분 진행한다.
  RawMessage receive(String text, {String? sender = 'sender'}) {
    final raw = RawMessage(
      text: text,
      receivedAt: clock(),
      source: MessageSource.manual,
      sender: sender,
    );
    clock.advance();
    return raw;
  }

  Future<(IngestResult, Transaction?)> ingest(String text) =>
      ingestMessage(receive(text), deps);

  Future<void> close() => db.close();
}

final DateTime harnessStart = DateTime(2026, 11, 27, 20);

Future<IngestHarness> openHarness({
  AppSettings settings = const AppSettings(),
}) async {
  final db = await openMemoryDb();
  final settingsRepo = SqlSettingsRepository(db);
  await settingsRepo.save(settings);
  final notifier = FakeNotifier();
  final widgets = MemoryWidgetGateway();
  final clock = TestClock(harnessStart);
  var counter = 0;
  final deps = IngestDeps(
    ledger: SqlLedgerRepository(db),
    settings: settingsRepo,
    hints: SqlFormatHintRepository(db),
    notifier: notifier,
    widgets: widgets,
    now: clock.call,
    newId: () => 'tx${++counter}',
  );
  return IngestHarness._(db, deps, notifier, widgets, clock);
}
