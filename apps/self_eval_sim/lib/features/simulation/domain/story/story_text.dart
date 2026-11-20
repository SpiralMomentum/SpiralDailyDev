import '../entities/text_book.dart';
import 'story_judge.dart';
import 'story_world.dart';

/// 이야기 문장 키 규칙. 없는 키는 [TextBook.of] 규칙대로 키 그대로 돌려준다.
///
/// 채널 id 는 `story.<w>` 이고, 틀 키(`story.<w>.<frameId>`, frameId 는 `f_` 로 시작)가
/// 기존 문항 키 형식과 같아서 [TextBook.question], [TextBook.choice] 와 발현 재료 풀이가
/// 그대로 동작한다.
extension StoryText on TextBook {
  /// 이야기 세계의 채널 id.
  static String channelOf(String worldId) => 'story.$worldId';

  String _w(String worldId) => channelOf(worldId);
  String _c(String worldId, String characterId) =>
      '${_w(worldId)}.char.$characterId';

  /// 세계 이름. 발현 재료의 채널 이름으로도 쓰인다.
  String storyName(String worldId) => channelName(_w(worldId));

  /// 세계 공통 말투 규칙 (프롬프트 전용). 없으면 빈 문자열.
  String storyStyle(String worldId) => style(_w(worldId));

  /// 세계 금지 표현 (성별 전제 표현 포함).
  List<String> storyAvoid(String worldId) => avoid(_w(worldId));

  String characterName(String worldId, String characterId) =>
      of('${_c(worldId, characterId)}.name');

  String characterPlace(String worldId, String characterId) =>
      of('${_c(worldId, characterId)}.place');

  /// 인물 배경 에셋 키. 없으면 [fallback] (채널 art).
  String characterArt(String worldId, String characterId, String fallback) =>
      entries['${_c(worldId, characterId)}.art'] ?? fallback;

  /// 질문 끝에 인물이 묻는 한마디. `ask.0`, `ask.1`, ... 을 [index] 순서로 돌려 쓴다.
  /// 하나도 없으면 빈 문자열.
  String characterAsk(String worldId, String characterId, int index) {
    final asks = _numbered('${_c(worldId, characterId)}.ask');
    return asks.isEmpty ? '' : asks[index % asks.length];
  }

  /// 인물 말투 규칙 (프롬프트 전용). 없으면 빈 문자열.
  String characterStyle(String worldId, String characterId) =>
      entries['${_c(worldId, characterId)}.style'] ?? '';

  /// 칭호를 밝히는 첫 줄. `{title}` 자리에 칭호.
  String characterReveal(String worldId, String characterId, String title) =>
      of('${_c(worldId, characterId)}.reveal').replaceAll('{title}', title);

  /// 다시 만난 결과의 첫 줄 앞에 붙는 짧은 말 ('역시'/'의외'). 인물 문장이 없으면 세계 공통,
  /// 그것도 없거나 첫 만남/재회 중립이면 빈 문자열.
  String revealPrefix(String worldId, String characterId, JudgmentTone tone) =>
      switch (tone) {
        JudgmentTone.confirmed || JudgmentTone.surprised =>
          entries['${_c(worldId, characterId)}.reveal.${tone.name}'] ??
              entries['${_w(worldId)}.reveal.${tone.name}'] ??
              '',
        JudgmentTone.first || JudgmentTone.neutral => '',
      };

  /// 근거 답을 짚는 줄. `{act}` 자리에 관형형 행동. `evidence.0`, `evidence.1`, ... 을
  /// [index] 순서로 돌려 쓴다. 인물 문장이 없으면 빈 문자열.
  String characterEvidence(
    String worldId,
    String characterId,
    String act, [
    int index = 0,
  ]) {
    final all = _numbered('${_c(worldId, characterId)}.evidence');
    return all.isEmpty ? '' : all[index % all.length].replaceAll('{act}', act);
  }

  /// 인물 대사에서 버릴 표현 (정규식). 없으면 빈 목록.
  List<String> characterAvoid(String worldId, String characterId) => [
    ?entries['${_c(worldId, characterId)}.avoid'],
  ];

  /// 인물 대사의 말끝 정규식. 없으면 빈 문자열.
  String characterEnding(String worldId, String characterId) =>
      entries['${_c(worldId, characterId)}.ending'] ?? '';

  /// `<prefix>.0`, `<prefix>.1`, ... 처럼 번호가 이어지는 문장 목록.
  List<String> _numbered(String prefix) => [
    for (var i = 0; entries.containsKey('$prefix.$i'); i++)
      entries['$prefix.$i']!,
  ];

  /// 인물이 이 결과에 붙인 별명.
  String characterTitle(String worldId, String characterId, String outcome) =>
      of('${_c(worldId, characterId)}.title.$outcome');

  /// 결과를 맺는 한 줄.
  String characterSaying(String worldId, String characterId, String outcome) =>
      of('${_c(worldId, characterId)}.saying.$outcome');

  String introFirst(String worldId, String characterId) =>
      of('${_c(worldId, characterId)}.intro.first');

  String introAgain(
    String worldId,
    String characterId,
    Relationship relationship,
  ) => of('${_c(worldId, characterId)}.intro.again.${relationship.name}');

  /// 소문을 듣고 처음 만나는 도입. `{source}` 자리에 소문 준 인물 이름.
  String introRumor(String worldId, String characterId, String source) => of(
    '${_c(worldId, characterId)}.intro.rumor',
  ).replaceAll('{source}', source);

  /// 관계별 말투 규칙 (프롬프트 전용). 없으면 빈 문자열.
  String relationshipStyle(String worldId, Relationship relationship) =>
      entries['${_w(worldId)}.rel.${relationship.name}.style'] ?? '';

  String variantText(String worldId, String axis, String variantId) =>
      of('${_w(worldId)}.var.$axis.$variantId');

  /// 변주 자리표시자(`{축}`)를 채운 질문.
  String frameQuestion(
    String worldId,
    String frameId,
    Map<String, String> variant,
  ) => _fill(worldId, question(_w(worldId), frameId), variant);

  /// 선택지 문장 (자리표시자 없음).
  String frameChoice(String worldId, String frameId, String choiceId) =>
      choice(_w(worldId), frameId, choiceId);

  /// 같은 틀이 다시 나올 때 지난 선택을 짚는 연결 문장.
  String frameRecall(
    String worldId,
    String frameId,
    String choiceId,
    Map<String, String> variant,
  ) => _fill(worldId, of('${_w(worldId)}.$frameId.recall.$choiceId'), variant);

  String eventIntro(String worldId, String eventId) =>
      of('${_w(worldId)}.event.$eventId.intro');

  /// 모델 입력용 관계 한 줄.
  String contextRelationship(String worldId, Relationship relationship) =>
      of('${_w(worldId)}.ctx.rel.${relationship.name}');

  /// 모델 입력용 판단 흐름 한 줄 (첫인상/확신/의외).
  String contextTone(String worldId, JudgmentTone tone) =>
      of('${_w(worldId)}.ctx.tone.${tone.name}');

  /// 모델 입력용 지난 근거 한 줄. `{choice}` 자리에 지난 선택지 문장.
  String contextPast(String worldId, String choiceText) =>
      of('${_w(worldId)}.ctx.past').replaceAll('{choice}', choiceText);

  /// 모델 입력용 소문 한 줄. `{source}` 자리에 소문 준 인물 이름.
  String contextRumor(String worldId, String source) =>
      of('${_w(worldId)}.ctx.rumor').replaceAll('{source}', source);

  String _fill(String worldId, String template, Map<String, String> variant) =>
      variant.entries.fold(
        template,
        (t, e) =>
            t.replaceAll('{${e.key}}', variantText(worldId, e.key, e.value)),
      );
}
