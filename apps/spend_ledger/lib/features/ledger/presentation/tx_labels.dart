import 'package:intl/intl.dart';

import '../domain/transaction.dart';

/// 분류 표시 이름.
String categoryLabel(SpendCategory c) => switch (c) {
  SpendCategory.spend => '지출',
  SpendCategory.prepaidCharge => '선불 충전',
  SpendCategory.transferOut => '송금',
  SpendCategory.internal => '내부이체',
  SpendCategory.prepaidUse => '선불 머니 사용',
  SpendCategory.refund => '환불',
  SpendCategory.unknown => '확인 필요',
};

/// 상태 표시 이름.
String statusLabel(TxStatus s) => switch (s) {
  TxStatus.pending => '확인 대기',
  TxStatus.included => '포함',
  TxStatus.excluded => '제외',
  TxStatus.duplicate => '중복',
  TxStatus.cancelled => '취소됨',
};

/// 상대가 비어 있으면 대신 보여 줄 이름.
String counterpartyLabel(Transaction t) =>
    t.counterparty.trim().isEmpty ? '알 수 없는 곳' : t.counterparty;

final DateFormat _when = DateFormat('M월 d일 HH:mm');

String formatWhen(DateTime t) => _when.format(t);
