import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';
import 'package:spend_ledger/features/ledger/presentation/candidates_cubit.dart';
import 'package:spend_ledger/features/message_filter/domain/name_registry.dart';
import 'package:spend_ledger/features/settings/domain/app_settings.dart';

import '../../fixtures/messages.dart';
import '../../support/failing_ledger.dart';
import '../../support/fakes.dart';

void main() {
  late IngestHarness h;
  tearDown(() => h.close());

  const names = NameRegistry(
    selfNames: ['홍길동'],
    chargeTargets: ['쿠팡페이'],
    prepaidMoneys: ['쿠페이머니'],
  );

  test('candidates split into three lists', () async {
    h = await openHarness(settings: const AppSettings(names: names));
    final (_, spend) = await h.ingest(kbApproval);
    final (_, review) = await h.ingest(noAmount);
    final (_, self) = await h.ingest(selfTransfer);
    final (_, prepaid) = await h.ingest(coupayMoneyPayment);
    h.clock.value = h.clock.value.subtract(const Duration(minutes: 3));
    final (_, dup) = await h.ingest(kbApproval);
    final cubit = CandidatesCubit(h.deps);

    await cubit.load();

    final s = cubit.state;
    expect(s.loading, isFalse);
    expect(s.waiting.map((t) => t.id), [spend!.id]);
    expect(s.needsReview.map((t) => t.id), [review!.id]);
    expect(dup!.status, TxStatus.duplicate);
    expect(s.auto.map((t) => t.id).toSet(), {self!.id, prepaid!.id, dup.id});
    final times = s.auto.map((t) => t.occurredAt).toList();
    expect(times, [...times]..sort((a, b) => b.compareTo(a)));
    await cubit.close();
  });

  test('auto list keeps only the last 90 days', () async {
    h = await openHarness(settings: const AppSettings(names: names));
    await h.ingest(selfTransfer);
    h.clock.advance(const Duration(days: 120));
    final cubit = CandidatesCubit(h.deps);

    await cubit.load();

    expect(cubit.state.auto, isEmpty);
    await cubit.close();
  });

  test('include moves item out of waiting', () async {
    h = await openHarness();
    final (_, a) = await h.ingest(kbApproval);
    final (_, b) = await h.ingest(shinhanApproval);
    final cubit = CandidatesCubit(h.deps);
    await cubit.load();
    expect(cubit.state.waiting, hasLength(2));

    await cubit.include(a!.id);

    expect(cubit.state.waiting.map((t) => t.id), [b!.id]);
    expect((await h.deps.ledger.byId(a.id))!.status, TxStatus.included);
    expect(h.notifier.cancelled, [a.id]);

    await cubit.exclude(b.id);

    expect(cubit.state.waiting, isEmpty);
    expect((await h.deps.ledger.byId(b.id))!.status, TxStatus.excluded);
    await cubit.close();
  });

  test('include still reloads when notification cancel fails', () async {
    h = await openHarness();
    final (_, a) = await h.ingest(kbApproval);
    final cubit = CandidatesCubit(h.deps);
    await cubit.load();
    h.notifier.failing = true;

    await cubit.include(a!.id);

    expect(cubit.state.waiting, isEmpty);
    await cubit.close();
  });

  test('load failure ends loading with an error', () async {
    h = await openHarness();
    final ledger = FailingLedger(h.deps.ledger)..failReads = true;
    final cubit = CandidatesCubit(withLedger(h.deps, ledger));

    await cubit.load();

    expect(cubit.state.loading, isFalse);
    expect(cubit.state.error, isNotNull);

    ledger.failReads = false;
    await cubit.load();

    expect(cubit.state.error, isNull);
    await cubit.close();
  });
}
