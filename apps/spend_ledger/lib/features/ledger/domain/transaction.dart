import 'package:equatable/equatable.dart';

import '../../parsing/domain/parsed_message.dart';

enum SpendCategory {
  spend,
  prepaidCharge,
  transferOut,
  internal,
  prepaidUse,
  refund,
  unknown,
}

enum TxStatus { pending, included, excluded, duplicate, cancelled }

class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.amount,
    required this.counterparty,
    required this.occurredAt,
    required this.receivedAt,
    required this.kind,
    required this.category,
    required this.status,
    required this.needsReview,
    required this.signature,
    this.linkedId,
    this.rawText,
    this.sender,
  });

  final String id;
  final int amount;
  final String counterparty;
  final DateTime occurredAt;
  final DateTime receivedAt;
  final MessageKind kind;
  final SpendCategory category;
  final TxStatus status;
  final String? linkedId;
  final String? rawText;
  final String? sender;
  final bool needsReview;
  final String signature;

  /// null 가능 필드는 `null`을 넘겨도 "변경 없음"이므로,
  /// 값을 지우려면 [clearLinkedId] / [clearRawText]를 true로 지정한다.
  Transaction copyWith({
    int? amount,
    String? counterparty,
    DateTime? occurredAt,
    SpendCategory? category,
    TxStatus? status,
    String? linkedId,
    bool clearLinkedId = false,
    String? rawText,
    bool clearRawText = false,
    String? sender,
    bool? needsReview,
  }) => Transaction(
    id: id,
    amount: amount ?? this.amount,
    counterparty: counterparty ?? this.counterparty,
    occurredAt: occurredAt ?? this.occurredAt,
    receivedAt: receivedAt,
    kind: kind,
    category: category ?? this.category,
    status: status ?? this.status,
    linkedId: clearLinkedId ? null : (linkedId ?? this.linkedId),
    rawText: clearRawText ? null : (rawText ?? this.rawText),
    sender: sender ?? this.sender,
    needsReview: needsReview ?? this.needsReview,
    signature: signature,
  );

  @override
  List<Object?> get props => [
    id,
    amount,
    counterparty,
    occurredAt,
    receivedAt,
    kind,
    category,
    status,
    linkedId,
    rawText,
    sender,
    needsReview,
    signature,
  ];
}
