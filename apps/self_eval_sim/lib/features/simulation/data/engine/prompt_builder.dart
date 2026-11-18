import '../../domain/entities/accumulation.dart';
import '../../domain/entities/evaluation.dart';

/// `assets/narration/prompts.json` 의 언어별 설정.
final class PromptSpec {
  const PromptSpec(this._json);

  final Map<String, dynamic> _json;

  String get base => _json['base'] as String;
  String get manifest => _json['manifest'] as String;
  String get answer => _json['answer'] as String;
  String get materialAttempt => _json['materialAttempt'] as String;
  String get materialManifest => _json['materialManifest'] as String;
  String get separateVoice => _json['separateVoice'] as String;
  String get sameVoice => _json['sameVoice'] as String;
  String get separateStyle => _json['separateStyle'] as String;
  String get language => _json['language'] as String;
  int get maxLength => _json['maxLength'] as int;
  int get baseLines => _json['baseLines'] as int;
  int get manifestLines => _json['manifestLines'] as int;
  int get minBaseLines => _json['minBaseLines'] as int;
  int get minManifestLines => _json['minManifestLines'] as int;
  List<RegExp> get banned => [
        for (final p in (_json['banned'] as List).cast<String>())
          p.startsWith('(?i)')
              ? RegExp(p.substring(4), caseSensitive: false)
              : RegExp(p),
      ];
}

/// 프롬프트 문자열을 만드는 순수 함수 모음. 자리표시자는 `{이름}` 형식이다.
abstract final class PromptBuilder {
  static String fill(String template, Map<String, Object> values) =>
      values.entries.fold(template, (t, e) => t.replaceAll('{${e.key}}', '${e.value}'));

  static String base(PromptSpec spec, BaseNarrationRequest r) => fill(spec.base, {
        'place': r.place,
        'speaker': r.speaker,
        'title': r.title,
        'answers': r.answers
            .map((a) => fill(spec.answer, {'q': a.$1, 'c': a.$2}))
            .join('\n'),
        'examples': r.examples.join('\n'),
        'lines': spec.baseLines,
        'maxLength': spec.maxLength,
        'language': spec.language,
      });

  static String manifestation(PromptSpec spec, ManifestationRequest r) =>
      fill(spec.manifest, {
        'voice': r.form == ManifestationForm.separate
            ? spec.separateVoice
            : fill(spec.sameVoice, {'speaker': r.speaker}),
        'title': r.title,
        'materials': r.materials
            .map(
              (m) => fill(
                m.kind == MaterialKind.manifestation
                    ? spec.materialManifest
                    : spec.materialAttempt,
                {'ago': m.ago, 'channel': m.channelName, 'choice': m.choiceText},
              ),
            )
            .join('\n'),
        'style': r.examples.isEmpty ? spec.separateStyle : r.examples.join('\n'),
        'lines': spec.manifestLines,
        'maxLength': spec.maxLength,
        'language': spec.language,
      });
}
