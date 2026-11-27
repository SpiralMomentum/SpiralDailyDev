import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/budget/domain/budget_alert.dart';
import 'package:spend_ledger/features/budget/domain/summary.dart';
import 'package:spend_ledger/features/confirm_notification/domain/notification_text.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';
import 'package:spend_ledger/features/parsing/domain/parsed_message.dart';

Transaction tx(int amount, String counterparty) => Transaction(
  id: 'id',
  amount: amount,
  counterparty: counterparty,
  occurredAt: DateTime(2026, 11, 27),
  receivedAt: DateTime(2026, 11, 27),
  kind: amount < 0 ? MessageKind.refund : MessageKind.approval,
  category: amount < 0 ? SpendCategory.refund : SpendCategory.spend,
  status: TxStatus.pending,
  needsReview: false,
  signature: 'sig',
);

void main() {
  test('spend body', () {
    expect(
      confirmBody(tx(1234567, '스타벅스')),
      '스타벅스에서 1,234,567원 지출이 있었던 것 같아요. 지출에 포함할까요?',
    );
  });

  test('spend body without merchant', () {
    expect(confirmBody(tx(8900, '')), '어딘가에서 8,900원 지출이 있었던 것 같아요. 지출에 포함할까요?');
  });

  test('refund body uses absolute amount', () {
    expect(confirmBody(tx(-6500, '스타벅스')), '스타벅스 환불 6,500원을 지출에서 뺄까요?');
  });

  test('budget alert bodies', () {
    final s = summarize(
      txs: const [],
      now: DateTime(2026, 11, 27),
      startDay: 1,
      budget: 1500000,
    );
    expect(
      budgetAlertBody(BudgetAlert.actualOver, s),
      '이번 달 예산 1,500,000원을 넘었어요.',
    );
    expect(
      budgetAlertBody(BudgetAlert.projectedOver, s),
      '이대로면 이번 달 예산을 넘을 것 같아요.',
    );
  });
}
