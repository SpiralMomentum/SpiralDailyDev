import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/parsing/domain/parsed_message.dart';
import 'package:spend_ledger/features/parsing/domain/parser.dart';

import '../../fixtures/messages.dart';

void main() {
  final receivedAt = DateTime(2026, 11, 27, 20, 0);

  ParsedMessage parse(String text, {DateTime? at}) =>
      parseMessage(text, receivedAt: at ?? receivedAt);

  void expectParsed(
    ParsedMessage p, {
    required int? amount,
    required MessageKind kind,
    String? counterparty,
    required DateTime occurredAt,
  }) {
    expect(p.amount, amount);
    expect(p.kind, kind);
    if (counterparty != null) expect(p.counterparty, counterparty);
    expect(p.occurredAt, occurredAt);
  }

  test('kb approval', () {
    expectParsed(
      parse(kbApproval),
      amount: 6500,
      kind: MessageKind.approval,
      counterparty: '스타벅스',
      occurredAt: DateTime(2026, 11, 27, 14, 3),
    );
  });

  test('shinhan single line', () {
    expectParsed(
      parse(shinhanApproval),
      amount: 12000,
      kind: MessageKind.approval,
      counterparty: '김밥천국',
      occurredAt: DateTime(2026, 11, 27, 12, 30),
    );
  });

  test('kb cancel', () {
    expectParsed(
      parse(kbCancel),
      amount: 6500,
      kind: MessageKind.cancel,
      counterparty: '스타벅스',
      occurredAt: DateTime(2026, 11, 27, 15, 10),
    );
  });

  test('bank withdrawal without 원', () {
    expectParsed(
      parse(chargeWithdrawal),
      amount: 100000,
      kind: MessageKind.withdrawal,
      counterparty: '쿠팡페이',
      occurredAt: DateTime(2026, 11, 27, 9, 0),
    );
  });

  test('prepaid money payment', () {
    expectParsed(
      parse(coupayMoneyPayment),
      amount: 30000,
      kind: MessageKind.approval,
      counterparty: '쿠팡',
      occurredAt: DateTime(2026, 11, 27, 18, 20),
    );
  });

  test('transfer recipient', () {
    expectParsed(
      parse(friendTransfer),
      amount: 30000,
      kind: MessageKind.transfer,
      counterparty: '김철수',
      occurredAt: receivedAt,
    );
  });

  test('card bill keeps card name', () {
    expectParsed(
      parse(cardBillWithdrawal),
      amount: 420000,
      kind: MessageKind.withdrawal,
      counterparty: '신한카드',
      occurredAt: DateTime(2026, 11, 25, 8, 0),
    );
  });

  test('no keyword falls back to approval', () {
    expectParsed(
      parse(noKeyword),
      amount: 8900,
      kind: MessageKind.approval,
      counterparty: '배달의민족',
      occurredAt: DateTime(2026, 11, 27, 19, 40),
    );
  });

  test('no amount', () {
    expectParsed(
      parse(noAmount),
      amount: null,
      kind: MessageKind.approval,
      occurredAt: receivedAt,
    );
  });

  test('skips balance before amount', () {
    expectParsed(
      parse(balanceFirst),
      amount: 12300,
      kind: MessageKind.approval,
      counterparty: 'GS25',
      occurredAt: DateTime(2026, 11, 27, 8, 10),
    );
  });

  test('year rollover', () {
    expectParsed(
      parse(
        '[Web발신]\n신한카드 승인 5,000원 12/31 23:50 편의점',
        at: DateTime(2027, 1, 1, 0, 5),
      ),
      amount: 5000,
      kind: MessageKind.approval,
      counterparty: '편의점',
      occurredAt: DateTime(2026, 12, 31, 23, 50),
    );
  });

  test('signature equals formatSignature of text and sender', () {
    final p = parseMessage(kbApproval, receivedAt: receivedAt, sender: 'KB');
    expect(p.signature.startsWith('KB|'), isTrue);
  });

  test('contentLines drops blanks and Web발신', () {
    expect(contentLines('[Web발신]\n  a \n\n b'), ['a', 'b']);
  });
}
