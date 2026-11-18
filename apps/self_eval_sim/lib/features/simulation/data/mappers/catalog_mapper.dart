import '../../domain/entities/catalog.dart';
import '../../domain/entities/text_book.dart';

/// 콘텐츠 JSON 을 도메인 모델로 바꾼다. 형식이 어긋나면 [FormatException].
abstract final class CatalogMapper {
  static ContentCatalog catalog(Map<String, dynamic> json) => ContentCatalog(
        questionsPerAttempt: json['questionsPerAttempt'] as int,
        channels: [
          for (final c in json['channels'] as List) _channel(c as Map<String, dynamic>),
        ],
      );

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
