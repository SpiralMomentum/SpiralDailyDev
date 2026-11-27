import 'parsed_message.dart';
import 'signature.dart';

// ---- 파서와 서명이 공유하는 정의 ----

final RegExp amountPattern = RegExp(r'(\d{1,3}(?:,\d{3})+|\d+)\s*원');
final RegExp _fallbackAmountPattern = RegExp(
  r'(출금|이체|송금|결제|승인)\s*(\d{1,3}(?:,\d{3})+|\d+)',
);
final RegExp _balanceBefore = RegExp(r'잔액|누적|한도|잔고|잔여');
final RegExp _balanceWithNumber = RegExp(
  r'(?:잔액|누적|한도|잔고|잔여)[^\s\d:：]*\s*[:：]?\s*\d[\d,]*\s*원?',
);
final RegExp _footerLine = RegExp(r'고객센터|문의|www|http');
final RegExp _phoneToken = RegExp(r'\d{2,4}-\d{3,4}(?:-\d{4})?');
final RegExp _cancelable = RegExp(r'취소\s*가능');
final RegExp _dateTimePattern = RegExp(
  r'(\d{1,2})[/.](\d{1,2})\s*(\d{1,2}):(\d{2})',
);
final RegExp _dateOnlyPattern = RegExp(r'(\d{1,2})월\s*(\d{1,2})일');

/// 종류 키워드 우선순위 순서. 서명 형태 코드에도 쓴다.
const List<(String, MessageKind)> kindKeywords = [
  ('취소', MessageKind.cancel),
  ('환불', MessageKind.refund),
  ('출금', MessageKind.withdrawal),
  ('자동이체', MessageKind.withdrawal),
  ('송금', MessageKind.transfer),
  ('이체', MessageKind.transfer),
  ('보냄', MessageKind.transfer),
  ('승인', MessageKind.approval),
  ('결제', MessageKind.approval),
  ('사용', MessageKind.approval),
];

const String _lineSeparator = '\n';

bool containsAmount(String line) =>
    amountPattern.hasMatch(line) || _fallbackAmountPattern.hasMatch(line);

bool containsDateTime(String line) =>
    _dateTimePattern.hasMatch(line) || _dateOnlyPattern.hasMatch(line);

/// 고객센터·문의·URL 안내 줄. 종류와 상대 판정에서 제외한다.
bool isFooterLine(String line) => _footerLine.hasMatch(line);

/// 줄에서 우선순위가 가장 높은 종류 키워드. 없으면 null.
/// 안내 줄과 `취소가능` 문구는 무시한다.
String? firstKindKeyword(String line) {
  if (isFooterLine(line)) return null;
  line = line.replaceAll(_cancelable, '');
  for (final (keyword, _) in kindKeywords) {
    if (line.contains(keyword)) return keyword;
  }
  return null;
}

/// trim 후 빈 줄과 `[Web발신]` 줄을 제외한 본문 줄.
List<String> contentLines(String text) => text
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty && line != '[Web발신]')
    .toList(growable: false);

ParsedMessage parseMessage(
  String text, {
  required DateTime receivedAt,
  String? sender,
}) {
  final body = contentLines(
    text,
  ).where((line) => !isFooterLine(line)).join('\n');
  final amount = _extractAmount(body);
  final kind = _extractKind(body, hasAmount: amount != null);
  return ParsedMessage(
    amount: amount,
    counterparty: cleanCounterparty(body, kind),
    occurredAt: _extractOccurredAt(body, receivedAt),
    kind: kind,
    signature: formatSignature(text, sender),
  );
}

int? _extractAmount(String body) {
  for (final match in amountPattern.allMatches(body)) {
    final start = match.start;
    final before = body.substring(start < 8 ? 0 : start - 8, start);
    if (_balanceBefore.hasMatch(before)) continue;
    return _toInt(match.group(1)!);
  }
  final fallback = _fallbackAmountPattern.firstMatch(body);
  return fallback == null ? null : _toInt(fallback.group(2)!);
}

int _toInt(String digits) => int.parse(digits.replaceAll(',', ''));

MessageKind _extractKind(String body, {required bool hasAmount}) {
  final keyword = firstKindKeyword(body);
  if (keyword != null) {
    return kindKeywords.firstWhere((entry) => entry.$1 == keyword).$2;
  }
  if (body.contains('입금')) return MessageKind.unknown;
  return hasAmount ? MessageKind.approval : MessageKind.unknown;
}

DateTime _extractOccurredAt(String body, DateTime receivedAt) {
  final withTime = _dateTimePattern.firstMatch(body);
  if (withTime != null) {
    return _resolve(
      receivedAt,
      month: int.parse(withTime.group(1)!),
      day: int.parse(withTime.group(2)!),
      hour: int.parse(withTime.group(3)!),
      minute: int.parse(withTime.group(4)!),
    );
  }
  final dateOnly = _dateOnlyPattern.firstMatch(body);
  if (dateOnly != null) {
    return _resolve(
      receivedAt,
      month: int.parse(dateOnly.group(1)!),
      day: int.parse(dateOnly.group(2)!),
      hour: receivedAt.hour,
      minute: receivedAt.minute,
    );
  }
  return receivedAt;
}

DateTime _resolve(
  DateTime receivedAt, {
  required int month,
  required int day,
  required int hour,
  required int minute,
}) {
  DateTime build(int year) => DateTime(year, month, day, hour, minute);
  final valid =
      month >= 1 &&
      month <= 12 &&
      hour < 24 &&
      minute < 60 &&
      build(receivedAt.year).month == month &&
      build(receivedAt.year).day == day;
  if (!valid) return receivedAt;
  final candidate = build(receivedAt.year);
  return candidate.isAfter(receivedAt.add(const Duration(days: 1)))
      ? build(receivedAt.year - 1)
      : candidate;
}

final RegExp _bracketToken = RegExp(r'\[[^\]]*\]|\([^)]*\)');
final RegExp _amountWithInstallment = RegExp(
  '${amountPattern.pattern}(?:\\s*(?:일시불|할부\\S*))?',
);
final RegExp _starToken = RegExp(r'\S*\*\S*');
final RegExp _kindWords = RegExp(
  '${kindKeywords.map((e) => e.$1).join('|')}|완료|안내',
);
final RegExp _digitsOnlyToken = RegExp(r'(?<!\S)[\d,]+(?!\S)');
final RegExp _cardBankToken = RegExp(r'\S*(?:카드|은행)\S*');
final RegExp _honorific = RegExp(r'(?:님에게|님|에게)$');

/// 문자 조각에서 상대(가맹점·수신자)만 남긴다. 못 찾으면 빈 문자열.
/// 힌트가 지정한 한 줄에도 같은 정리를 적용할 수 있도록 공개한다.
String cleanCounterparty(String segmentSource, MessageKind kind) {
  var s = segmentSource;
  String sep(Match _) => _lineSeparator;
  s = s.replaceAllMapped(_bracketToken, sep);
  s = s.replaceAllMapped(_cancelable, sep);
  s = s.replaceAllMapped(_phoneToken, sep);
  s = s.replaceAllMapped(_balanceWithNumber, sep);
  s = s.replaceAllMapped(_amountWithInstallment, sep);
  s = s.replaceAllMapped(_dateTimePattern, sep);
  s = s.replaceAllMapped(_dateOnlyPattern, sep);
  s = s.replaceAllMapped(_starToken, sep);
  s = s.replaceAllMapped(_kindWords, sep);
  s = s.replaceAllMapped(_digitsOnlyToken, sep);
  final dropsCardBank =
      kind == MessageKind.approval ||
      kind == MessageKind.cancel ||
      kind == MessageKind.refund;
  if (dropsCardBank) s = s.replaceAllMapped(_cardBankToken, sep);

  final pieces = s
      .split(_lineSeparator)
      .map((piece) => piece.trim())
      .where((piece) => piece.length >= 2)
      .toList(growable: false);
  if (pieces.isEmpty) return '';
  return pieces.last.replaceFirst(_honorific, '').trim();
}
