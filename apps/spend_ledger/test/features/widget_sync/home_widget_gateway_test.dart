import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/budget/domain/budget_alert.dart';
import 'package:spend_ledger/features/ingest/domain/ingest.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';
import 'package:spend_ledger/features/settings/domain/app_settings.dart';
import 'package:spend_ledger/features/widget_sync/data/home_widget_gateway.dart';

import '../../fixtures/messages.dart';
import '../../support/fakes.dart';

void main() {
  test('save stores every entry then updates the three providers', () async {
    final saved = <String, String>{};
    final updated = <String>[];
    final order = <String>[];
    final g = HomeWidgetGateway(
      saveData: (k, v) async {
        order.add('save');
        saved[k] = v;
      },
      updateWidget: (name) async {
        order.add('update');
        updated.add(name);
      },
    );

    await g.save({'total': '1,000원', 'ratio': '', 'asOf': '11/28 09:05'});

    expect(saved, {'total': '1,000원', 'ratio': '', 'asOf': '11/28 09:05'});
    expect(updated, [
      'com.spiralmomentum.spend_ledger.SmallSpendWidget',
      'com.spiralmomentum.spend_ledger.MediumSpendWidget',
      'com.spiralmomentum.spend_ledger.LargeSpendWidget',
    ]);
    expect(order.indexOf('update'), greaterThan(order.lastIndexOf('save')));
  });
  test('throwing gateway does not break ingest or budget alert', () async {
    final h = await openHarness(settings: const AppSettings(budget: 7000));
    final d = IngestDeps(
      ledger: h.deps.ledger,
      settings: h.deps.settings,
      hints: h.deps.hints,
      seen: h.deps.seen,
      notifier: h.deps.notifier,
      widgets: HomeWidgetGateway(
        saveData: (_, _) async => throw StateError('channel down'),
        updateWidget: (_) async => throw StateError('channel down'),
      ),
      now: h.deps.now,
      newId: h.deps.newId,
    );

    final (result, tx) = await ingestMessage(h.receive(kbApproval), d);
    expect(tx, isNotNull);
    expect(result, IngestResult.stored);
    await resolveCandidate(tx!.id, true, d);
    await h.ingest(noAmount);

    expect(h.notifier.alerts, [BudgetAlert.projectedOver]);
    expect((await d.ledger.byId(tx.id))!.status, TxStatus.included);
    await h.close();
  });
}
