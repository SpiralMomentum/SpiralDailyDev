import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:utils/utils.dart';

import '../../balance/domain/calendar_date.dart';
import 'tone.dart';

/// 한 말투의 키-문장 테이블. 키마다 변형 1개 이상.
class ToneTable extends Equatable {
  const ToneTable({required this.id, required this.phrases});

  final ToneId id;
  final Map<String, List<String>> phrases;

  @override
  List<Object?> get props => [id, phrases];
}

/// `{ "<key>": ["문장", ...] }` 형식을 파싱한다. 값은 비어 있지 않은 문자열 배열이어야 한다.
Result<ToneTable> parseToneTable(ToneId id, String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException catch (e, st) {
    return ErrorResult(
      ParsingFailure(
        message: 'tone ${id.name}: invalid json',
        cause: e,
        stackTrace: st,
      ),
    );
  }
  if (decoded is! Map<String, dynamic>) {
    return ErrorResult(
      ParsingFailure(message: 'tone ${id.name}: root is not an object'),
    );
  }
  final phrases = <String, List<String>>{};
  for (final entry in decoded.entries) {
    final value = entry.value;
    if (value is! List || value.isEmpty || value.any((v) => v is! String)) {
      return ErrorResult(
        ParsingFailure(
          message:
              'tone ${id.name}: "${entry.key}" must be a non-empty string array',
        ),
      );
    }
    phrases[entry.key] = List.unmodifiable(value.cast<String>());
  }
  return Success(ToneTable(id: id, phrases: Map.unmodifiable(phrases)));
}

/// 날짜 기반으로 하루 하나의 변형을 고른다. 같은 날에는 위젯/알림/앱이 같은 문장을 쓴다.
/// 키가 없으면 키 문자열을 그대로 돌려준다.
String pickPhrase(ToneTable t, String key, CalendarDate today) {
  final variants = t.phrases[key];
  if (variants == null || variants.isEmpty) return key;
  return variants[today.epochDay % variants.length];
}

final _placeholder = RegExp(r'\{(\w+)\}');

/// `{name}`을 vars 값으로 치환한다. vars에 없는 변수는 그대로 둔다.
String fillPlaceholders(String template, Map<String, String> vars) => template
    .replaceAllMapped(_placeholder, (m) => vars[m.group(1)] ?? m.group(0)!);
