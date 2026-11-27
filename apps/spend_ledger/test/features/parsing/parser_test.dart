import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/parsing/domain/parsed_message.dart';
import 'package:spend_ledger/features/parsing/domain/parser.dart';

import '../../fixtures/messages.dart';

void main() {
  _regressions();
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

void _regressions() {
  final receivedAt = DateTime(2026, 11, 27, 20, 0);
  ParsedMessage parse(String t) => parseMessage(t, receivedAt: receivedAt);

  test('deposit is unknown kind', () {
    final p = parse('[KB]11/27 10:00 123456**789 홍길동 입금 50,000원 잔액 1,284,000원');
    expect(p.kind, MessageKind.unknown);
    expect(p.amount, 50000);
  });

  test('footer ignored', () {
    final p = parse(
      '[Web발신]\nKB국민카드1*3*승인\n홍*동님\n6,500원 일시불\n11/27 14:03\n김밥천국\n고객센터 1588-1688',
    );
    expect(p.counterparty, '김밥천국');
  });

  test('누적금액 removed', () {
    final p = parse(
      '[Web발신]\n신한카드 승인 12,000원 11/27 12:30 김밥천국\n누적금액 1,246,560원',
    );
    expect(p.counterparty, '김밥천국');
    expect(p.amount, 12000);
  });

  test('잔여한도 removed', () {
    final p = parse('[Web발신]\n삼성카드 승인 9,000원 11/27 12:00 이디야\n잔여한도 1,000,000원');
    expect(p.counterparty, '이디야');
    expect(p.amount, 9000);
  });

  test('잔액 colon', () {
    final p = parse('[Web발신]\n하나카드 잔액:5,000원 승인 3,000원 11/27 08:00 CU');
    expect(p.amount, 3000);
    expect(p.counterparty, 'CU');
  });

  test('취소가능 is not cancel', () {
    final p = parse('[Web발신]\n현대카드 승인 7,700원 11/27 13:00 스타벅스 취소가능');
    expect(p.kind, MessageKind.approval);
    expect(p.counterparty, '스타벅스');
  });

  test('single line footer keeps body', () {
    final p = parse('[카드] 승인 7,700원 스타벅스 문의 1577-6000');
    expect(p.amount, 7700);
    expect(p.kind, MessageKind.approval);
    expect(p.counterparty, '스타벅스');
  });

  test('phone pattern inside merchant kept', () {
    final p = parse('[Web발신]\n신한카드 승인 3,000원 11/27 10:00 GS25-123');
    expect(p.counterparty, 'GS25-123');
  });
}
