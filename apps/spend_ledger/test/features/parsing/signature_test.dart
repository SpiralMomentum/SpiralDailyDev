import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/parsing/domain/signature.dart';

import '../../fixtures/messages.dart';

void main() {
  test('same format same signature', () {
    const other =
        '[Web발신]\nKB국민카드1*3*승인\n홍*동님\n12,000원 일시불\n11/28 09:00\n이마트\n누적1,246,560원';
    expect(formatSignature(other, 'KB'), formatSignature(kbApproval, 'KB'));
  });

  test('different sender different signature', () {
    expect(
      formatSignature(kbApproval, 'KB'),
      isNot(formatSignature(kbApproval, 'SH')),
    );
  });

  test('null sender uses empty prefix', () {
    expect(formatSignature(kbApproval, null).startsWith('|'), isTrue);
  });
}
