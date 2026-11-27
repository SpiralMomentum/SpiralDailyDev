import 'package:equatable/equatable.dart';

import 'parser.dart';
import 'signature.dart';

/// 사용자가 고쳐 준 문자 형식. 같은 서명의 문자에서 금액 순번과 상대 줄을 재사용한다.
class FormatHint extends Equatable {
  const FormatHint({
    required this.signature,
    this.amountOrdinal,
    this.counterpartyLine,
  });

  factory FormatHint.fromJson(Map<String, dynamic> json) => FormatHint(
    signature: json['signature'] as String,
    amountOrdinal: json['amountOrdinal'] as int?,
    counterpartyLine: json['counterpartyLine'] as int?,
  );

  final String signature;
  final int? amountOrdinal;
  final int? counterpartyLine;

  Map<String, dynamic> toJson() => {
    'signature': signature,
    'amountOrdinal': amountOrdinal,
    'counterpartyLine': counterpartyLine,
  };

  @override
  List<Object?> get props => [signature, amountOrdinal, counterpartyLine];
}

/// 확정된 금액·상대로부터 형식 힌트를 만든다. 둘 다 찾지 못하면 null.
FormatHint? learnHint(
  String text,
  String? sender, {
  required int amount,
  required String counterparty,
}) {
  final ordinal = allWonAmounts(bodyOf(text)).indexOf(amount);
  final line = counterparty.isEmpty
      ? -1
      : contentLines(text).indexWhere((l) => l.contains(counterparty));
  if (ordinal < 0 && line < 0) return null;
  return FormatHint(
    signature: formatSignature(text, sender),
    amountOrdinal: ordinal < 0 ? null : ordinal,
    counterpartyLine: line < 0 ? null : line,
  );
}
