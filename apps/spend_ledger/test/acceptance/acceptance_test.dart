import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/confirm_notification/domain/notification_text.dart';
import 'package:spend_ledger/features/ingest/domain/ingest.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';
import 'package:spend_ledger/features/message_filter/domain/name_registry.dart';
import 'package:spend_ledger/features/settings/domain/app_settings.dart';

import '../fixtures/messages.dart';
import '../support/fakes.dart';

const names = NameRegistry(
  selfNames: ['홍길동', '신한카드'],
  chargeTargets: ['쿠팡페이'],
  prepaidMoneys: ['쿠페이머니'],
);

void main() {
  late IngestHarness h;
  setUp(() async {
    h = await openHarness(settings: const AppSettings(names: names));
  });
  tearDown(() => h.close());

  Future<int> total() async => (await refreshOutputs(h.deps)).periodTotal;

  test('charge then money payment counts once', () async {
    final (_, charge) = await h.ingest(chargeWithdrawal);
    await resolveCandidate(charge!.id, true, h.deps);
    expect(h.notifier.asked, hasLength(1));

    final (result, payment) = await h.ingest(coupayMoneyPayment);

    expect(result, IngestResult.stored);
    expect(payment!.status, TxStatus.excluded);
    expect(h.notifier.asked, hasLength(1));
    expect(await total(), 100000);
  });

  test('friend transfer counts, self and card bill do not', () async {
    final (_, friend) = await h.ingest(friendTransfer);
    await h.ingest(selfTransfer);
    await h.ingest(cardBillWithdrawal);

    expect(h.notifier.asked.map((t) => t.id), [friend!.id]);
    await resolveCandidate(friend.id, true, h.deps);
    expect(await total(), 30000);
  });

  test('cancel removes original', () async {
    final (_, approval) = await h.ingest(kbApproval);
    await resolveCandidate(approval!.id, true, h.deps);
    expect(await total(), 6500);

    await h.ingest(kbCancel);

    expect(await total(), 0);
    expect((await h.deps.ledger.byId(approval.id))!.status, TxStatus.cancelled);
  });

  test('unanswered stays out of total', () async {
    await h.ingest(kbApproval);

    expect(await total(), 0);
    expect(await h.deps.ledger.byStatus({TxStatus.pending}), hasLength(1));
    expect(h.widgets.last!['pending'], '1');
  });

  test('new format without 승인 notifies', () async {
    await h.ingest(noKeyword);

    expect(h.notifier.asked, hasLength(1));
    expect(confirmBody(h.notifier.asked.single), contains('배달의민족에서 8,900원'));
  });
}
