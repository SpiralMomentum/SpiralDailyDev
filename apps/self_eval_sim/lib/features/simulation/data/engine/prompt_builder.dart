import '../../domain/entities/accumulation.dart';
import '../../domain/entities/evaluation.dart';

/// `assets/narration/prompts.json` 의 언어별 설정.
final class PromptSpec {
  const PromptSpec(this._json);

  final Map<String, dynamic> _json;

  String get base => _json['base'] as String;
  String get manifest => _json['manifest'] as String;
  String get answer => _json['answer'] as String;

  /// 답/기록 뒤에 붙는 성향 표시. 예: ` (성실성 높음)`.
  String get traitSuffix => (_json['traitSuffix'] as String?) ?? ' ({trait})';
  String get materialAttempt => _json['materialAttempt'] as String;
  String get materialManifest => _json['materialManifest'] as String;
  String get separateVoice => _json['separateVoice'] as String;
  String get sameVoice => _json['sameVoice'] as String;
  String get separateStyle => _json['separateStyle'] as String;
  String get language => _json['language'] as String;

  /// 성격 단정 문장의 언어별 형태 예시. 한국어는 지시문에 직접 씀.
  String get judge => (_json['judge'] as String?) ?? '';
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
  static String fill(String template, Map<String, Object> values) => values
      .entries
      .fold(template, (t, e) => t.replaceAll('{${e.key}}', '${e.value}'));

  static String _trait(PromptSpec spec, String trait) =>
      trait.isEmpty ? '' : fill(spec.traitSuffix, {'trait': trait});

  static Map<String, Object> _profile(TypeProfile? p) => {
    'theory': p?.theoryName ?? '',
    'type': p?.label ?? '',
    'desc': p?.description ?? '',
    'strength': p?.strength ?? '',
    'weakness': p?.weakness ?? '',
  };

  /// 많이 드러난 성향 상위 [limit] 개. 예: `성실성 높음 9, 외향성 낮음 7`.
  static String tally(List<(String, int)> tally, {int limit = 6}) =>
      tally.take(limit).map((t) => '${t.$1} ${t.$2}').join(', ');

  static String base(PromptSpec spec, BaseNarrationRequest r) => fill(
    spec.base,
    {
      ..._profile(r.profile),
      'place': r.place,
      'speaker': r.speaker,
      'title': r.title,
      'reveal': r.reveal,
      'answers': r.answers
          .map(
            (a) =>
                fill(spec.answer, {'q': a.$1, 'c': a.$2}) + _trait(spec, a.$3),
          )
          .join('\n'),
      'examples': r.examples.join('\n'),
      'lines': spec.baseLines,
      'maxLength': spec.maxLength,
      'language': spec.language,
      'judge': spec.judge,
    },
  );

  static String manifestation(PromptSpec spec, ManifestationRequest r) => fill(
    spec.manifest,
    {
      ..._profile(r.profile),
      'tally': tally(r.tally),
      'total': r.totalAnswers,
      'today': r.today.join('; '),
      'voice': r.form == ManifestationForm.separate
          ? spec.separateVoice
          : fill(spec.sameVoice, {'speaker': r.speaker}),
      'title': r.title,
      'materials': r.materials
          .map(
            (m) =>
                fill(
                  m.kind == MaterialKind.manifestation
                      ? spec.materialManifest
                      : spec.materialAttempt,
                  {
                    'ago': m.ago,
                    'channel': m.channelName,
                    'choice': m.choiceText,
                  },
                ) +
                _trait(spec, m.trait),
          )
          .join('\n'),
      'style': r.examples.isEmpty ? spec.separateStyle : r.examples.join('\n'),
      'lines': spec.manifestLines,
      'maxLength': spec.maxLength,
      'language': spec.language,
      'judge': spec.judge,
    },
  );
}
