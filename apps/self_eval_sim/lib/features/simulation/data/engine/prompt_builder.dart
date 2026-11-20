import '../../domain/entities/accumulation.dart';
import '../../domain/entities/evaluation.dart';

/// `assets/narration/prompts.json` 의 언어별 설정.
final class PromptSpec {
  const PromptSpec(this._json);

  final Map<String, dynamic> _json;

  String get base => _json['base'] as String;

  /// 이야기 모드 결과 프롬프트. 없으면 [base].
  String get storyBase => (_json['storyBase'] as String?) ?? base;

  /// 이야기 모드 답 한 줄. 없으면 [answer].
  String get storyAnswer => (_json['storyAnswer'] as String?) ?? answer;
  int get storyBaseLines => (_json['storyBaseLines'] as int?) ?? baseLines;
  int get minStoryBaseLines =>
      (_json['minStoryBaseLines'] as int?) ?? minBaseLines;

  /// 이야기 결과가 규칙에 걸려 버려지면 다시 생성하는 횟수.
  int get storyRetries => (_json['storyRetries'] as int?) ?? 0;

  /// 이 글자 수(공백 제외) 이상 이어서 겹치면 되풀이로 본다.
  int get echoLength => (_json['echoLength'] as int?) ?? 9;
  String get manifest => _json['manifest'] as String;
  String get answer => _json['answer'] as String;

  /// 맥락 줄 앞 머리줄. 맥락이 있을 때만 프롬프트에 들어간다.
  String get contextHeading => (_json['contextHeading'] as String?) ?? '';

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
    for (final p in (_json['banned'] as List).cast<String>()) pattern(p),
  ];

  /// 정규식 문자열. 앞에 `(?i)` 가 있으면 대소문자를 구분하지 않는다.
  static RegExp pattern(String p) => p.startsWith('(?i)')
      ? RegExp(p.substring(4), caseSensitive: false)
      : RegExp(p);
}

/// 프롬프트 문자열을 만드는 순수 함수 모음. 자리표시자는 `{이름}` 형식이다.
abstract final class PromptBuilder {
  static String fill(String template, Map<String, Object> values) => values
      .entries
      .fold(template, (t, e) => t.replaceAll('{${e.key}}', '${e.value}'));

  static String _trait(PromptSpec spec, String trait) =>
      trait.isEmpty ? '' : fill(spec.traitSuffix, {'trait': trait});

  /// 맥락 줄이 있으면 앞에 줄바꿈과 머리줄을 붙이고, 없으면 빈 문자열 (머리줄도 빠진다).
  static String _context(PromptSpec spec, List<String> context) =>
      context.isEmpty ? '' : '\n${spec.contextHeading}\n${context.join('\n')}';

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

  static String base(PromptSpec spec, BaseNarrationRequest r) =>
      fill(r.story ? spec.storyBase : spec.base, {
        ..._profile(r.profile),
        'place': r.place,
        'speaker': r.speaker,
        'title': r.title,
        'reveal': r.reveal,
        'answers': r.answers
            .map(
              (a) =>
                  fill(r.story ? spec.storyAnswer : spec.answer, {
                    'q': a.$1,
                    'c': a.$2,
                  }) +
                  _trait(spec, a.$3),
            )
            .join('\n'),
        'examples': r.examples.join('\n'),
        'style': r.style,
        'context': _context(spec, r.context),
        'lines': r.story ? spec.storyBaseLines : spec.baseLines,
        'maxLength': spec.maxLength,
        'language': spec.language,
        'judge': spec.judge,
      });

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
      // 말투 규칙도 예시도 없으면 (별도 장면) 낯선 목소리 말투.
      'style': r.examples.isEmpty && r.style.isEmpty
          ? spec.separateStyle
          : [r.style, ...r.examples].where((s) => s.isNotEmpty).join('\n'),
      'lines': spec.manifestLines,
      'maxLength': spec.maxLength,
      'language': spec.language,
      'judge': spec.judge,
    },
  );
}
