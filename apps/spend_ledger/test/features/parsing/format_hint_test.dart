import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/parsing/domain/format_hint.dart';
import 'package:spend_ledger/features/parsing/domain/parser.dart';
import 'package:spend_ledger/features/parsing/domain/signature.dart';

void main() {
  final receivedAt = DateTime(2026, 11, 27, 20, 0);

  const a = '[Web발신]\n우리카드 승인\n홍*동\n맛있는분식 본점\n7,000원\n본사 고객센터 문의\n누적 90,000원';
  const b = '[Web발신]\n우리카드 승인\n홍*동\n행복마트 역삼점\n3,000원\n본사 고객센터 문의\n누적 93,000원';

  test('learned counterparty applies to next message of same format', () {
    final before = parseMessage(a, receivedAt: receivedAt);
    expect(before.counterparty, '본사');

    final hint = learnHint(a, null, amount: 7000, counterparty: '맛있는분식 본점');
    expect(hint, isNotNull);
    expect(hint!.counterpartyLine, 2);
    expect(hint.amountOrdinal, 0);

    final parsed = parseMessage(b, receivedAt: receivedAt, hint: hint);
    expect(parsed.counterparty, '행복마트 역삼점');
    expect(parsed.amount, 3000);
  });

  test('learned ordinal picks second amount', () {
    const first = '[Web발신]\n신한 체크 잔액 5,000원\n승인 2,500원 카페';
    const second = '[Web발신]\n신한 체크 잔액 8,000원\n승인 4,100원 카페';
    final hint = learnHint(first, null, amount: 2500, counterparty: '카페');
    expect(hint!.amountOrdinal, 1);
    expect(
      parseMessage(second, receivedAt: receivedAt, hint: hint).amount,
      4100,
    );
  });

  test('hint ignored for other signature', () {
    final hint = learnHint(a, null, amount: 7000, counterparty: '맛있는분식 본점');
    const other = '[Web발신]\n국민카드 승인 1,000원 편의점';
    expect(
      parseMessage(other, receivedAt: receivedAt, hint: hint),
      parseMessage(other, receivedAt: receivedAt),
    );
    expect(formatSignature(other, null), isNot(hint!.signature));
  });

  test('returns null when amount absent', () {
    expect(learnHint(a, null, amount: 123, counterparty: '없는가게'), isNull);
  });

  test('json round trip', () {
    final hint = learnHint(a, null, amount: 7000, counterparty: '맛있는분식 본점');
    expect(FormatHint.fromJson(hint!.toJson()), hint);
  });
}
