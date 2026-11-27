import 'package:equatable/equatable.dart';

class FilterRule extends Equatable {
  const FilterRule({
    this.senderPattern,
    this.includeKeywords = const [],
    this.excludeKeywords = const [],
  });

  factory FilterRule.fromJson(Map<String, dynamic> json) => FilterRule(
        senderPattern: json['senderPattern'] as String?,
        includeKeywords:
            List<String>.from(json['includeKeywords'] as List? ?? const []),
        excludeKeywords:
            List<String>.from(json['excludeKeywords'] as List? ?? const []),
      );

  final String? senderPattern;
  final List<String> includeKeywords;
  final List<String> excludeKeywords;

  Map<String, dynamic> toJson() => {
        'senderPattern': senderPattern,
        'includeKeywords': includeKeywords,
        'excludeKeywords': excludeKeywords,
      };

  @override
  List<Object?> get props => [senderPattern, includeKeywords, excludeKeywords];
}

const List<FilterRule> defaultFilterRules = [
  FilterRule(
    includeKeywords: ['승인', '결제', '출금', '이체', '송금', '취소', '환불'],
    excludeKeywords: ['결제예정', '광고', '인증번호', '입금'],
  ),
];
