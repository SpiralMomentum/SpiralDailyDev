import '../../message_filter/domain/name_registry.dart';
import '../../message_filter/domain/raw_message.dart';
import '../../parsing/domain/parsed_message.dart';
import 'merchant_match.dart';
import 'transaction.dart';

class LedgerDecision {
  const LedgerDecision({
    required this.incoming,
    required this.updated,
    required this.notify,
  });

  final Transaction incoming;
  final List<Transaction> updated;
  final bool notify;
}

const Duration _duplicateWindow = Duration(minutes: 5);

LedgerDecision decide({
  required RawMessage raw,
  required ParsedMessage parsed,
  required NameRegistry names,
  required List<Transaction> recent,
  required String newId,
}) {
  final amount = parsed.amount;
  Transaction build(
    int signed,
    SpendCategory category,
    TxStatus status, {
    bool needsReview = false,
    String? linkedId,
  }) => Transaction(
    id: newId,
    amount: signed,
    counterparty: parsed.counterparty,
    occurredAt: parsed.occurredAt,
    receivedAt: raw.receivedAt,
    kind: parsed.kind,
    category: category,
    status: status,
    linkedId: linkedId,
    rawText: raw.text,
    sender: raw.sender,
    needsReview: needsReview,
    signature: parsed.signature,
  );

  // 1. 금액 없음 또는 종류 불명(예: 입금): 사용자 확인 필요, 집계 제외.
  if (amount == null || parsed.kind == MessageKind.unknown) {
    return LedgerDecision(
      incoming: build(
        amount ?? 0,
        SpendCategory.unknown,
        TxStatus.pending,
        needsReview: true,
      ),
      updated: const [],
      notify: false,
    );
  }

  bool mentions(List<String> list) =>
      list.any((n) => n.isNotEmpty && raw.text.contains(n));

  // 2. 취소/환불
  if (parsed.kind == MessageKind.cancel || parsed.kind == MessageKind.refund) {
    final original = _findOriginal(recent, parsed, amount);
    if (original != null) {
      return LedgerDecision(
        incoming: build(
          -amount,
          SpendCategory.refund,
          TxStatus.excluded,
          linkedId: original.id,
        ),
        updated: [original.copyWith(status: TxStatus.cancelled)],
        notify: false,
      );
    }
    final prepaid = mentions(names.prepaidMoneys);
    return LedgerDecision(
      incoming: build(
        -amount,
        SpendCategory.refund,
        prepaid ? TxStatus.excluded : TxStatus.pending,
      ),
      updated: const [],
      notify: !prepaid,
    );
  }

  // 4/5. 분류
  final (category, classifiedStatus, classifiedNotify) = _classify(
    parsed.kind,
    mentions,
    names,
  );

  // 3. 중복: 분류는 그대로, 상태만 duplicate
  final isDuplicate = recent.any(
    (t) =>
        t.status != TxStatus.duplicate &&
        t.amount == amount &&
        (t.receivedAt.difference(raw.receivedAt)).abs() <= _duplicateWindow &&
        merchantMatches(t.counterparty, parsed.counterparty),
  );

  return LedgerDecision(
    incoming: build(
      amount,
      category,
      isDuplicate ? TxStatus.duplicate : classifiedStatus,
    ),
    updated: const [],
    notify: isDuplicate ? false : classifiedNotify,
  );
}

(SpendCategory, TxStatus, bool) _classify(
  MessageKind kind,
  bool Function(List<String>) mentions,
  NameRegistry names,
) {
  if (kind == MessageKind.approval) {
    return mentions(names.prepaidMoneys)
        ? (SpendCategory.prepaidUse, TxStatus.excluded, false)
        : (SpendCategory.spend, TxStatus.pending, true);
  }
  // withdrawal / transfer
  if (mentions(names.chargeTargets)) {
    return (SpendCategory.prepaidCharge, TxStatus.pending, true);
  }
  if (mentions(names.selfNames)) {
    return (SpendCategory.internal, TxStatus.excluded, false);
  }
  return (SpendCategory.transferOut, TxStatus.pending, true);
}

/// 취소 대상 원거래. 이미 취소됐거나 중복으로 표시된 거래는 대상이 아니다.
Transaction? _findOriginal(
  List<Transaction> recent,
  ParsedMessage parsed,
  int amount,
) {
  Transaction? best;
  for (final t in recent) {
    final live =
        t.status != TxStatus.cancelled && t.status != TxStatus.duplicate;
    final eligible =
        t.status == TxStatus.included ||
        t.status == TxStatus.pending ||
        (t.category == SpendCategory.prepaidUse && live);
    if (!eligible ||
        t.amount != amount ||
        !merchantMatches(t.counterparty, parsed.counterparty) ||
        t.occurredAt.isAfter(parsed.occurredAt)) {
      continue;
    }
    if (best == null || t.occurredAt.isAfter(best.occurredAt)) best = t;
  }
  return best;
}
