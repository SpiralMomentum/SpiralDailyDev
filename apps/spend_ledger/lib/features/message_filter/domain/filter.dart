import 'filter_rule.dart';
import 'raw_message.dart';

final RegExp _amountPattern = RegExp(r'\d[\d,]*\s*원');

bool _applies(FilterRule rule, String? sender) {
  final pattern = rule.senderPattern;
  if (pattern == null) return true;
  return sender != null && sender.contains(pattern);
}

bool _containsAny(String text, List<String> keywords) =>
    keywords.any(text.contains);

bool passesFilter(RawMessage m, List<FilterRule> rules) {
  final applicable = rules.where((r) => _applies(r, m.sender)).toList();
  if (applicable.isEmpty) return true;
  if (applicable.any((r) => _containsAny(m.text, r.excludeKeywords))) {
    return false;
  }
  if (_amountPattern.hasMatch(m.text)) return true;
  final withInclude =
      applicable.where((r) => r.includeKeywords.isNotEmpty).toList();
  if (withInclude.isEmpty) return true;
  return withInclude.any((r) => _containsAny(m.text, r.includeKeywords));
}
