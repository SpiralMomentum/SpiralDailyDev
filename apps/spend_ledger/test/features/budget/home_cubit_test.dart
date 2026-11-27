import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/budget/presentation/home_cubit.dart';
import 'package:spend_ledger/features/ingest/domain/ingest.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';
import 'package:spend_ledger/features/settings/domain/app_settings.dart';

import '../../fixtures/messages.dart';
import '../../support/fakes.dart';

void main() {
  late IngestHarness h;
  tearDown(() => h.close());

  test('home loads summary', () async {
    h = await openHarness(settings: const AppSettings(budget: 300000));
    final (_, a) = await h.ingest(kbApproval);
    await resolveCandidate(a!.id, true, h.deps);
    await h.ingest(shinhanApproval);
    final cubit = HomeCubit(h.deps);
    expect(cubit.state.loading, isTrue);
    expect(cubit.state.summary, isNull);

    await cubit.load();

    expect(cubit.state.loading, isFalse);
    final s = cubit.state.summary!;
    expect(s.periodTotal, 6500);
    expect(s.todayTotal, 6500);
    expect(s.budget, 300000);
    expect(s.pendingCount, 1);
    expect(s.recent.single.counterparty, '스타벅스');
    await cubit.close();
  });

  test('manual paste stores and reloads', () async {
    h = await openHarness();
    final cubit = HomeCubit(h.deps);

    final stored = await cubit.addManual(kbApproval);
    final filtered = await cubit.addManual(deposit);

    expect(stored, IngestResult.stored);
    expect(filtered, IngestResult.filtered);
    expect(cubit.state.summary!.pendingCount, 1);
    final saved = await h.deps.ledger.byStatus({TxStatus.pending});
    expect(saved.single.counterparty, '스타벅스');
    expect(h.notifier.asked, hasLength(1));
    await cubit.close();
  });
}
