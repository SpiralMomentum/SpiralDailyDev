import 'package:equatable/equatable.dart';

import '../entities/accumulation.dart';
import '../entities/catalog.dart';
import '../entities/evaluation.dart';
import '../entities/quiz_question.dart';
import '../entities/text_book.dart';
import '../policies/result_composer.dart';
import 'frame_picker.dart';
import 'story_judge.dart';
import 'story_ledger.dart';
import 'story_record.dart';
import 'story_text.dart';
import 'story_world.dart';

/// 만남 하나의 준비: 누구를, 어떤 관계로, 어떤 질문으로 만나는지와 도입 문장.
final class MeetingSetup extends Equatable {
  const MeetingSetup({
    required this.character,
    required this.relationship,
    required this.frames,
    required this.intro,
    this.event,
    required this.number,
  });

  final StoryCharacter character;
  final Relationship relationship;
  final List<PickedFrame> frames;
  final List<String> intro;
  final StoryEvent? event;

  /// 이번 만남 순번 (1부터).
  final int number;

  @override
  List<Object?> get props => [
    character,
    relationship,
    // PickedFrame 은 Equatable 이 아니라 값으로 비교한다.
    [
      for (final f in frames) [f.frame, f.variant, f.recallChoiceId],
    ],
    intro,
    event,
    number,
  ];
}

/// 대사 생성 전에 확정되고 저장까지 끝난 만남.
/// [pastAnswer] 는 다시 만난 경우 지난 만남의 근거 답 하나, [rumorSourceId] 는 소문 준 인물,
/// [priorAnswerCount] 는 이번 만남 전에 이 인물에게 한 답 수.
final class MeetingPlan extends Equatable {
  const MeetingPlan({
    required this.setup,
    required this.meeting,
    required this.judgment,
    required this.attemptPlan,
    this.pastAnswer,
    this.rumorSourceId,
    this.priorAnswerCount = 0,
  });

  final MeetingSetup setup;
  final StoryMeeting meeting;
  final Judgment judgment;
  final AttemptPlan attemptPlan;
  final StoryAnswer? pastAnswer;
  final String? rumorSourceId;
  final int priorAnswerCount;

  @override
  List<Object?> get props => [
    setup,
    meeting,
    judgment,
    attemptPlan,
    pastAnswer,
    rumorSourceId,
    priorAnswerCount,
  ];
}

/// 이야기 만남의 문항, 도입, 모델 요청, 결과 장면을 조립하는 순수 함수 모음.
/// 이론 이름, 결과 코드, 관계 이름은 화면 문장에 넣지 않는다 (관계는 프롬프트에만).
abstract final class StoryComposer {
  static String channelId(StoryWorld world) => StoryText.channelOf(world.id);

  /// 화면에 그릴 문항. 질문 id 는 (틀, 변주) 조합 키.
  static List<QuizQuestion> questions(
    StoryWorld world,
    TextBook text,
    MeetingSetup setup,
  ) => [
    for (final (i, p) in setup.frames.indexed)
      QuizQuestion(
        id: StoryAnswer(
          frameId: p.frame.id,
          variant: p.variant,
          choiceId: '',
        ).comboKey,
        text: _questionText(world, text, p, setup.character.id, i),
        choices: [
          for (final c in p.frame.choices)
            QuizChoice(
              id: c.id,
              text: text.frameChoice(world.id, p.frame.id, c.id),
            ),
        ],
      ),
  ];

  /// [지난 선택을 짚는 말] 상황 문장, 줄을 바꿔 인물이 묻는 한마디(따옴표).
  static String _questionText(
    StoryWorld world,
    TextBook text,
    PickedFrame p,
    String characterId,
    int index,
  ) {
    final q = text.frameQuestion(world.id, p.frame.id, p.variant);
    final recall = p.recallChoiceId;
    final scene = recall == null
        ? q
        : '${text.frameRecall(world.id, p.frame.id, recall, p.variant)} $q';
    final ask = text.characterAsk(world.id, characterId, index);
    return ask.isEmpty ? scene : '$scene\n"$ask"';
  }

  /// 소문 준 인물: 만난 적 있는 아는 인물 중 가장 최근에 만난 인물. 없으면 null.
  static String? rumorSource(StoryLedger ledger, String characterId) {
    String? best;
    var bestAt = 0;
    for (final id in ledger.acquaintancesOf(characterId)) {
      final at = ledger.lastMetAt(id) ?? 0;
      if (best == null || at > bestAt) {
        best = id;
        bestAt = at;
      }
    }
    return best;
  }

  /// 지난 만남에서 근거로 짚을 답 하나. 이번 판단 결과를 드러낸 답을 앞세우고,
  /// 없으면 지난 만남의 첫 답. 처음 만나면 null. [exclude] 의 틀에 한 답은 고르지 않는다
  /// (남는 답이 없으면 null).
  static StoryAnswer? pastEvidence(
    StoryWorld world,
    StoryLedger ledger,
    StoryCharacter character,
    String outcome, {
    Set<String> exclude = const {},
  }) {
    final last = ledger.meetings
        .where((m) => m.characterId == character.id)
        .lastOrNull;
    return strongest(world, character, outcome, [
      for (final a in last?.answers ?? const <StoryAnswer>[])
        if (!exclude.contains(a.frameId)) a,
    ]);
  }

  /// [answers] 중 [outcome] 을 가장 많이 드러낸 답 (같으면 앞선 답). 비면 null.
  static StoryAnswer? strongest(
    StoryWorld world,
    StoryCharacter character,
    String outcome,
    List<StoryAnswer> answers,
  ) {
    if (answers.isEmpty) return null;
    final theory = world.theoryById(character.theoryId);
    if (theory == null) return answers.first;
    final raw =
        theory.outcomeAlias.entries
            .where((e) => e.value == outcome)
            .firstOrNull
            ?.key ??
        outcome;
    int support(StoryAnswer a) {
      final poles = _poles(world, theory, a);
      return switch (theory.mode) {
        TheoryMode.dominant => poles.contains(raw) ? 1 : 0,
        TheoryMode.code => poles.where(raw.contains).length,
      };
    }

    return answers.reduce((a, b) => support(b) > support(a) ? b : a);
  }

  /// 도입 문장: 사건 도입, 그다음 첫 만남(소문이 있으면 소문 도입) 또는 관계별 재회 도입.
  /// 재회면 지난 만남 답 하나(지난 판단을 드러낸 답 우선)를 짚는 연결 문장을 한 줄 더한다.
  /// 이번 질문 틀 [asked] 에 한 답은 질문 앞에 연결 문장이 붙으므로 도입에서 짚지 않는다.
  static List<String> intro(
    StoryWorld world,
    TextBook text,
    StoryLedger ledger,
    StoryCharacter character,
    Relationship relationship,
    StoryEvent? event, {
    Set<String> asked = const {},
  }) {
    final source = rumorSource(ledger, character.id);
    final lastOutcome = ledger.lastOutcome(character.id);
    final recall = lastOutcome == null
        ? null
        : pastEvidence(world, ledger, character, lastOutcome, exclude: asked);
    return [
      if (event != null) text.eventIntro(world.id, event.id),
      if (ledger.metCount(character.id) > 0) ...[
        text.introAgain(world.id, character.id, relationship),
        if (recall != null)
          text.frameRecall(
            world.id,
            recall.frameId,
            recall.choiceId,
            recall.variant,
          ),
      ] else if (source != null)
        text.introRumor(
          world.id,
          character.id,
          text.characterName(world.id, source),
        )
      else
        text.introFirst(world.id, character.id),
    ];
  }

  static String _title(StoryWorld world, TextBook text, MeetingPlan plan) =>
      text.characterTitle(
        world.id,
        plan.setup.character.id,
        plan.judgment.outcome,
      );

  /// 칭호를 밝히는 첫 줄. 다시 만났으면 tone 별 접두('역시'/'의외')를 앞에 붙인다.
  static String _revealLine(StoryWorld world, TextBook text, MeetingPlan plan) {
    final id = plan.setup.character.id;
    final reveal = text.characterReveal(
      world.id,
      id,
      _title(world, text, plan),
    );
    final prefix = text.revealPrefix(world.id, id, plan.judgment.tone);
    return prefix.isEmpty ? reveal : '$prefix $reveal';
  }

  /// 이번 만남에서 결과를 가장 잘 드러낸 답을 인물 말투로 짚는 줄. 선택지 문장을
  /// 관형형으로 바꿔 `{act}` 자리에 넣는다 (예: '샛길로 들어간다' -> '샛길로 들어가는').
  /// 인물 문장이 없거나 답이 없으면 빈 문자열.
  static String evidenceLine(
    StoryWorld world,
    TextBook text,
    MeetingPlan plan,
  ) {
    final character = plan.setup.character;
    final answer = strongest(
      world,
      character,
      plan.judgment.outcome,
      plan.meeting.answers,
    );
    if (answer == null) return '';
    final act = adnominal(
      text.frameChoice(world.id, answer.frameId, answer.choiceId),
    );
    // 이 인물과의 만남 순번으로 문장을 돌려 써서 다시 만날 때마다 말이 바뀐다.
    final met = plan.priorAnswerCount ~/ StoryRules.questionsPerMeeting;
    return text.characterEvidence(world.id, character.id, act, met);
  }

  /// '~는다'/'~ㄴ다'로 끝나는 현재형 문장을 관형형('~는')으로. 그 밖의 끝은 그대로 둔다.
  static String adnominal(String sentence) {
    final s = sentence.trim().replaceFirst(RegExp(r'[.!]+$'), '');
    if (s.endsWith('는다')) return s.substring(0, s.length - 1);
    if (!s.endsWith('다') || s.length < 2) return s;
    final last = s.codeUnitAt(s.length - 2);
    const base = 0xAC00;
    const nieun = 4; // 종성 ㄴ
    if (last < base || last > 0xD7A3 || (last - base) % 28 != nieun) return s;
    final open = String.fromCharCode(last - nieun);
    return '${s.substring(0, s.length - 2)}$open는';
  }

  static List<String> _profileLines(
    TextBook text,
    StoryCharacter character,
    String outcome,
  ) {
    final p = text.typeProfile(character.theoryId, outcome);
    return [p.description, p.strength, p.weakness];
  }

  /// 결과 대사 모델 요청. 말투는 세계 + 인물 + 관계 순.
  static BaseNarrationRequest baseRequest(
    StoryWorld world,
    TextBook text,
    MeetingPlan plan,
  ) {
    final w = world.id;
    final character = plan.setup.character;
    final relationship = plan.meeting.relationship;
    final theory = world.theoryById(character.theoryId);
    final title = _title(world, text, plan);
    final past = plan.pastAnswer;
    final source = plan.rumorSourceId;
    final reveal = _revealLine(world, text, plan);
    final evidence = evidenceLine(world, text, plan);
    return BaseNarrationRequest(
      story: true,
      echoes: [
        reveal,
        if (evidence.isNotEmpty) evidence,
        for (final a in plan.meeting.answers)
          text.frameQuestion(w, a.frameId, a.variant),
      ],
      languageCode: text.languageCode,
      speaker: text.characterName(w, character.id),
      place: text.characterPlace(w, character.id),
      title: title,
      answers: [
        for (final a in plan.meeting.answers)
          (
            text.frameQuestion(w, a.frameId, a.variant),
            text.frameChoice(w, a.frameId, a.choiceId),
            theory == null
                ? ''
                : _traits(text, theory, _poles(world, theory, a)),
          ),
      ],
      examples: const [],
      fallbackLines: _profileLines(text, character, plan.judgment.outcome),
      profile: text.typeProfile(character.theoryId, plan.judgment.outcome),
      reveal: evidence.isEmpty ? reveal : '$reveal\n$evidence',
      style: _join([
        text.storyStyle(w),
        text.characterStyle(w, character.id),
        text.relationshipStyle(w, relationship),
      ]),
      avoid: [...text.storyAvoid(w), ...text.characterAvoid(w, character.id)],
      ending: text.characterEnding(w, character.id),
      context: [
        text.contextRelationship(w, relationship),
        text.contextTone(w, plan.judgment.tone),
        if (past != null)
          text.contextPast(w, text.frameChoice(w, past.frameId, past.choiceId)),
        if (source != null) text.contextRumor(w, text.characterName(w, source)),
      ],
    );
  }

  /// 누적 발현 대사 요청. 유형/성향 표/답 수는 이 인물의 판단 기준이다.
  /// 재료는 기존 규칙대로 풀고, 이 세계의 이야기 재료에는 인물 이론으로 읽은 성향을 붙인다.
  static ManifestationRequest manifestationRequest(
    StoryWorld world,
    TextBook text,
    MeetingPlan plan,
  ) {
    final w = world.id;
    final character = plan.setup.character;
    final theory = world.theoryById(character.theoryId);
    final manifestation = plan.attemptPlan.manifestation!;
    final attempt = plan.attemptPlan.attempt;
    return ManifestationRequest(
      languageCode: text.languageCode,
      form: manifestation.form,
      speaker: text.characterName(w, character.id),
      title: _title(world, text, plan),
      materials: [
        for (final ref in manifestation.materials)
          _material(world, text, theory, ref, attempt.index),
      ],
      profile: text.typeProfile(character.theoryId, plan.judgment.outcome),
      tally: _tally(text, character.theoryId, plan.judgment.tally),
      totalAnswers: plan.priorAnswerCount + plan.meeting.answers.length,
      today: [
        for (final a in plan.meeting.answers)
          text.frameChoice(w, a.frameId, a.choiceId),
      ],
      style: manifestation.form == ManifestationForm.mixed
          ? _join([text.storyStyle(w), text.characterStyle(w, character.id)])
          : '',
      avoid: text.storyAvoid(w),
    );
  }

  /// 결과 장면: 칭호를 밝히는 첫 줄, 대사(모델 또는 프로필 3줄), 맺음 문장.
  static EvaluationResult result({
    required StoryWorld world,
    required TextBook text,
    required MeetingPlan plan,
    Narration? base,
    ManifestationText? manifest,
  }) {
    final w = world.id;
    final character = plan.setup.character;
    final outcome = plan.judgment.outcome;
    final title = _title(world, text, plan);
    final scene = Scene(
      kind: SceneKind.base,
      art: text.characterArt(w, character.id, w),
      place: text.characterPlace(w, character.id),
      speaker: text.characterName(w, character.id),
      lines: [
        _revealLine(world, text, plan),
        if (evidenceLine(world, text, plan) case final e when e.isNotEmpty) e,
        ...(base?.lines ?? _profileLines(text, character, outcome)),
        text.characterSaying(w, character.id, outcome),
      ],
    );
    final form = plan.attemptPlan.manifestation?.form;
    return EvaluationResult(
      channelId: channelId(world),
      attemptIndex: plan.attemptPlan.attempt.index,
      archetype: 0,
      title: title,
      scenes: form != null && manifest != null
          ? ResultComposer.withManifestation(scene, form, manifest)
          : [scene],
      manifestationForm: manifest == null ? null : form,
      baseSource: base?.source ?? NarrationSource.template,
      manifestationSource: manifest?.source,
    );
  }

  static ResolvedMaterial _material(
    StoryWorld world,
    TextBook text,
    Theory? theory,
    MaterialRef ref,
    int currentIndex,
  ) {
    final resolved = ResultComposer.resolve(ref, currentIndex, text);
    if (theory == null || ref.channelId != channelId(world)) return resolved;
    return ResolvedMaterial(
      kind: resolved.kind,
      ago: resolved.ago,
      channelName: resolved.channelName,
      choiceText: resolved.choiceText,
      trait: _traits(
        text,
        theory,
        _poles(
          world,
          theory,
          StoryAnswer(
            frameId: ref.questionId,
            variant: const {},
            choiceId: ref.choiceId,
          ),
        ),
      ),
    );
  }

  /// 성향 표를 (성향 이름, 표 수) 많은 순으로. 소문 반 표는 반올림하고 0 은 뺀다.
  static List<(String, int)> _tally(
    TextBook text,
    String theoryId,
    Map<String, double> tally,
  ) => [
    for (final e in tally.entries)
      if (e.value.round() > 0)
        (
          ResultComposer.plainLabel(text.poleLabel(theoryId, e.key)),
          e.value.round(),
        ),
  ]..sort((a, b) => b.$2.compareTo(a.$2));

  static String _traits(TextBook text, Theory theory, List<String> poles) =>
      poles
          .map((p) => ResultComposer.plainLabel(text.poleLabel(theory.id, p)))
          .join(', ');

  static List<String> _poles(StoryWorld world, Theory theory, StoryAnswer a) {
    final choice = world
        .frameById(a.frameId)
        ?.choices
        .where((c) => c.id == a.choiceId)
        .firstOrNull;
    return choice == null ? const [] : StoryJudge.poles(theory, choice);
  }

  static String _join(List<String> parts) =>
      parts.where((s) => s.isNotEmpty).join('\n');
}
