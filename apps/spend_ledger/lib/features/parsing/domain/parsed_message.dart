import 'package:equatable/equatable.dart';

enum MessageKind { approval, withdrawal, transfer, cancel, refund, unknown }

/// 문자 한 통을 해석한 결과. 상대를 찾지 못하면 [counterparty]는 빈 문자열.
class ParsedMessage extends Equatable {
  const ParsedMessage({
    required this.amount,
    required this.counterparty,
    required this.occurredAt,
    required this.kind,
    required this.signature,
  });

  final int? amount;
  final String counterparty;
  final DateTime occurredAt;
  final MessageKind kind;
  final String signature;

  @override
  List<Object?> get props => [
    amount,
    counterparty,
    occurredAt,
    kind,
    signature,
  ];
}
