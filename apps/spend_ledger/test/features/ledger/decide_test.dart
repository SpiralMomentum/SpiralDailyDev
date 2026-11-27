import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/ledger/domain/decide.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';
import 'package:spend_ledger/features/message_filter/domain/name_registry.dart';
import 'package:spend_ledger/features/message_filter/domain/raw_message.dart';
import 'package:spend_ledger/features/parsing/domain/parser.dart';

import '../../fixtures/messages.dart';

const names = NameRegistry(
  selfNames: ['홍길동', '신한카드'],
  chargeTargets: ['쿠팡페이'],
  prepaidMoneys: ['쿠페이머니'],
);
final base = DateTime(2026, 11, 27, 14, 5);

RawMessage rawOf(String text, {DateTime? at}) => RawMessage(
  text: text,
  receivedAt: at ?? base,
  source: MessageSource.manual,
  sender: 'sender',
);

LedgerDecision run(
  String text, {
  DateTime? at,
  List<Transaction> recent = const [],
  String id = 'new',
}) {
  final raw = rawOf(text, at: at);
  return decide(
    raw: raw,
    parsed: parseMessage(text, receivedAt: raw.receivedAt),
    names: names,
    recent: recent,
    newId: id,
  );
}

Transaction past(
  String text,
  TxStatus status, {
  DateTime? at,
  String id = 'old',
}) => run(text, at: at, id: id).incoming.copyWith(status: status);

void main() {
  test('card approval is pending spend with notify', () {
    final d = run(kbApproval);
    expect(d.incoming.category, SpendCategory.spend);
    expect(d.incoming.status, TxStatus.pending);
    expect(d.incoming.amount, 6500);
    expect(d.incoming.rawText, kbApproval);
    expect(d.incoming.sender, 'sender');
    expect(d.incoming.receivedAt, base);
    expect(d.notify, isTrue);
    expect(d.updated, isEmpty);
  });

  test('charge withdrawal is prepaidCharge pending', () {
    final d = run(chargeWithdrawal);
    expect(d.incoming.category, SpendCategory.prepaidCharge);
    expect(d.incoming.status, TxStatus.pending);
    expect(d.notify, isTrue);
  });

  test('prepaid money payment auto excluded', () {
    final d = run(coupayMoneyPayment);
    expect(d.incoming.category, SpendCategory.prepaidUse);
    expect(d.incoming.status, TxStatus.excluded);
    expect(d.notify, isFalse);
  });

  test('friend transfer is transferOut', () {
    final d = run(friendTransfer);
    expect(d.incoming.category, SpendCategory.transferOut);
    expect(d.incoming.status, TxStatus.pending);
    expect(d.notify, isTrue);
  });

  test('self transfer internal excluded', () {
    final d = run(selfTransfer);
    expect(d.incoming.category, SpendCategory.internal);
    expect(d.incoming.status, TxStatus.excluded);
    expect(d.notify, isFalse);
  });

  test('card bill internal excluded', () {
    final d = run(cardBillWithdrawal);
    expect(d.incoming.category, SpendCategory.internal);
    expect(d.incoming.status, TxStatus.excluded);
    expect(d.notify, isFalse);
  });

  test('cancel matches included original', () {
    final original = past(
      kbApproval,
      TxStatus.included,
      at: DateTime(2026, 11, 27, 14, 5),
    );
    final d = run(
      kbCancel,
      at: DateTime(2026, 11, 27, 15, 10),
      recent: [original],
    );
    expect(d.updated.single.id, 'old');
    expect(d.updated[0].status, TxStatus.cancelled);
    expect(d.incoming.amount, -6500);
    expect(d.incoming.category, SpendCategory.refund);
    expect(d.incoming.status, TxStatus.excluded);
    expect(d.incoming.linkedId, 'old');
    expect(d.notify, isFalse);
  });

  test('cancel picks latest of several matching originals', () {
    final early = past(
      kbApproval,
      TxStatus.included,
      at: DateTime(2026, 11, 27, 9, 0),
      id: 'early',
    ).copyWith(occurredAt: DateTime(2026, 11, 27, 9, 0));
    final late = past(kbApproval, TxStatus.included, id: 'late');
    final d = run(
      kbCancel,
      at: DateTime(2026, 11, 27, 15, 10),
      recent: [late, early],
    );
    expect(d.incoming.linkedId, 'late');
  });

  test('cancel does not match excluded or already cancelled original', () {
    for (final s in [
      TxStatus.excluded,
      TxStatus.cancelled,
      TxStatus.duplicate,
    ]) {
      final d = run(
        kbCancel,
        at: DateTime(2026, 11, 27, 15, 10),
        recent: [past(kbApproval, s)],
      );
      expect(d.updated, isEmpty, reason: '$s');
      expect(d.incoming.status, TxStatus.pending, reason: '$s');
    }
  });

  test('cancel matches prepaidUse without effect', () {
    const cancelText = '[쿠팡] 쿠페이머니 결제 취소 30,000원\n11/27 19:00 쿠팡';
    final original = run(
      coupayMoneyPayment,
      at: DateTime(2026, 11, 27, 18, 20),
    ).incoming;
    expect(original.status, TxStatus.excluded);
    final d = run(
      cancelText,
      at: DateTime(2026, 11, 27, 19, 0),
      recent: [original],
    );
    expect(d.updated.single.status, TxStatus.cancelled);
    expect(d.incoming.status, TxStatus.excluded);
    expect(d.incoming.amount, -30000);
    expect(d.incoming.linkedId, original.id);
    expect(d.notify, isFalse);
  });

  test('cancel without original becomes negative pending', () {
    final d = run(kbCancel, at: DateTime(2026, 11, 27, 15, 10));
    expect(d.incoming.category, SpendCategory.refund);
    expect(d.incoming.amount, -6500);
    expect(d.incoming.status, TxStatus.pending);
    expect(d.incoming.linkedId, isNull);
    expect(d.notify, isTrue);
    expect(d.updated, isEmpty);
  });

  test('cancel without original mentioning prepaid money is excluded', () {
    final d = run('[쿠팡] 쿠페이머니 결제 취소 30,000원\n11/27 19:00 쿠팡');
    expect(d.incoming.amount, -30000);
    expect(d.incoming.status, TxStatus.excluded);
    expect(d.notify, isFalse);
  });

  test('duplicate within 5 minutes', () {
    final first = past(kbApproval, TxStatus.included);
    final d = run(
      kbApproval,
      at: base.add(const Duration(minutes: 3)),
      recent: [first],
    );
    expect(d.incoming.status, TxStatus.duplicate);
    expect(d.incoming.category, SpendCategory.spend);
    expect(d.notify, isFalse);
  });

  test('same message after 6 minutes is not duplicate', () {
    final first = past(kbApproval, TxStatus.included);
    final d = run(
      kbApproval,
      at: base.add(const Duration(minutes: 6)),
      recent: [first],
    );
    expect(d.incoming.status, TxStatus.pending);
    expect(d.notify, isTrue);
  });

  test('earlier duplicate-status transaction does not make a duplicate', () {
    final first = past(kbApproval, TxStatus.duplicate);
    final d = run(
      kbApproval,
      at: base.add(const Duration(minutes: 1)),
      recent: [first],
    );
    expect(d.incoming.status, TxStatus.pending);
  });

  test('no amount needs review', () {
    final d = run(noAmount);
    expect(d.incoming.category, SpendCategory.unknown);
    expect(d.incoming.status, TxStatus.pending);
    expect(d.incoming.needsReview, isTrue);
    expect(d.incoming.amount, 0);
    expect(d.notify, isFalse);
  });

  test('unknown kind with amount needs review', () {
    final d = run('[KB]11/27 10:00 123456**789 홍길동 입금 50,000원 잔액 1,284,000원');
    expect(d.incoming.category, SpendCategory.unknown);
    expect(d.incoming.status, TxStatus.pending);
    expect(d.incoming.needsReview, isTrue);
    expect(d.incoming.amount, 50000);
    expect(d.notify, isFalse);
  });

  test('copyWith can clear nullable fields', () {
    final t = run(kbApproval).incoming.copyWith(linkedId: 'x');
    final cleared = t.copyWith(clearRawText: true, clearLinkedId: true);
    expect(cleared.rawText, isNull);
    expect(cleared.linkedId, isNull);
    expect(t.copyWith(status: TxStatus.included).rawText, kbApproval);
  });
}
