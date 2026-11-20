import '../../domain/entities/catalog.dart';
import '../../domain/entities/text_book.dart';

/// 콘텐츠 JSON 을 도메인 모델로 바꾼다. 형식이 어긋나면 [FormatException].
abstract final class CatalogMapper {
  static ContentCatalog catalog(Map<String, dynamic> json) => ContentCatalog(
    questionsPerAttempt: json['questionsPerAttempt'] as int,
    theories: [
      for (final t in (json['theories'] as List?) ?? const [])
        theory(t as Map<String, dynamic>),
    ],
    channels: [
      for (final c in json['channels'] as List)
        _channel(c as Map<String, dynamic>),
    ],
  );

  /// 이론 한 개를 읽는다. 이야기 세계 매퍼와 공유한다.
  static Theory theory(Map<String, dynamic> t) => Theory(
    id: t['id'] as String,
    mode: TheoryMode.values.byName(t['mode'] as String),
    axes: [for (final a in t['axes'] as List) (a as List).cast<String>()],
    measures: t['measures'] as String?,
    poleAlias: _strMap(t['poleAlias']),
    outcomeAlias: _strMap(t['outcomeAlias']),
  );

  static Map<String, String> _strMap(Object? v) => {
    for (final e in ((v as Map?) ?? const {}).entries)
      e.key as String: e.value as String,
  };

  static Channel _channel(Map<String, dynamic> json) => Channel(
    id: json['id'] as String,
    art: json['art'] as String,
    archetypeCount: json['archetypeCount'] as int,
    questions: [
      for (final q in json['questions'] as List)
        Question(
          id: (q as Map<String, dynamic>)['id'] as String,
          choices: [
            for (final c in q['choices'] as List)
              Choice(
                id: (c as Map<String, dynamic>)['id'] as String,
                archetype: c['archetype'] as int,
                traits: {
                  for (final e in ((c['traits'] as Map?) ?? const {}).entries)
                    e.key as String: (e.value as List).cast<String>(),
                },
              ),
          ],
        ),
    ],
  );

  static TextBook textBook(String languageCode, Map<String, dynamic> json) =>
      TextBook(
        languageCode: languageCode,
        entries: json.map((k, v) => MapEntry(k, v as String)),
      );
}
