import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/evaluation.dart';
import 'package:self_eval_sim/features/simulation/domain/policies/material_selector.dart';
import 'package:self_eval_sim/features/simulation/domain/repositories/narration_engine.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_composer.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_judge.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_record.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_use_cases.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_world.dart';
import 'package:utils/utils.dart';

import '../../../../support/fixtures.dart';
import '../../../../support/story_fixtures.dart';

/// 받은 요청을 기록하는 엔진. [fail] 이면 모든 요청에 실패한다.
class _Engine implements NarrationEngine {
  _Engine({this.fail = false, this.log});

  final bool fail;
  final List<String>? log;
  final bases = <BaseNarrationRequest>[];
  final manifests = <ManifestationRequest>[];

  @override
  Future<Result<Narration>> baseLines(
    BaseNarrationRequest request,
    Random random,
  ) async {
    log?.add('engine');
    bases.add(request);
    if (fail) return const ErrorResult(ParsingFailure(message: 'engine'));
    return const Success(
      Narration(lines: ['모델 1', '모델 2'], source: NarrationSource.model),
    );
  }

  @override
  Future<Result<ManifestationText>> manifestation(
    ManifestationRequest request,
    Random random,
  ) async {
    manifests.add(request);
    if (fail) return const ErrorResult(ParsingFailure(message: 'engine'));
    return const Success(
      ManifestationText(
        lines: ['발현 1'],
        separateSpeaker: '목소리',
        separatePlace: '어딘가',
        source: NarrationSource.model,
      ),
    );
  }
}

class _LoggedStory extends InMemoryStoryRepository {
  _LoggedStory(this.log);

  final List<String> log;

  @override
  Future<Result<void>> append(String worldId, StoryMeeting meeting) {
    log.add('story');
    return super.append(worldId, meeting);
  }
}

class _LoggedAccumulation extends InMemoryAccumulationRepository {
  _LoggedAccumulation(this.log);

  final List<String> log;

  @override
  Future<Result<void>> save(AccumulationState next) {
    log.add('accumulation');
    return super.save(next);
  }
}

/// 객잔 주인(bigfive)이 질문 4개를 받을 수 있게 bigfive 틀(f_help, f_trade)을 4개로 바꾼 세계.
/// 선택지는 c1 = C+, c2 = C-, c3 = 이 이론에서 중립(태그 없음).
final _world = StoryWorld(
  id: miniWorld.id,
  characters: miniWorld.characters,
  theories: miniWorld.theories,
  frames: [
    for (var i = 1; i <= 4; i++)
      StoryFrame(
        id: 'f_b$i',
        axes: const ['who'],
        choices: const [
          FrameChoice(
            id: 'c1',
            traits: {
              'bigfive': ['C+'],
            },
          ),
          FrameChoice(
            id: 'c2',
            traits: {
              'bigfive': ['C-'],
            },
          ),
          FrameChoice(id: 'c3', traits: {}),
        ],
      ),
    ...miniWorld.frames.where((f) => f.id != 'f_help' && f.id != 'f_trade'),
  ],
  variants: miniWorld.variants,
  events: miniWorld.events,
  links: miniWorld.links,
);

void main() {
  final text = storyTextFor(_world);
  final now = DateTime.utc(2026, 11, 20);

  Future<MeetingSetup> start(InMemoryStoryRepository story, int seed) async =>
      (await StartMeetingUseCase(story, Random(seed))(
        _world,
        text,
      )).dataOrNull!;

  Future<MeetingPlan> planWith(
    InMemoryStoryRepository story,
    InMemoryAccumulationRepository acc,
    MeetingSetup setup,
    List<String> choiceIds,
  ) async => (await PlanMeetingUseCase(story, acc, Random(1), () => now)(
    world: _world,
    setup: setup,
    choiceIds: choiceIds,
  )).dataOrNull!;

  test('첫 만남: 객잔 주인, 질문 4개, 관계 정해짐', () async {
    final setup = await start(InMemoryStoryRepository(), 1);
    expect(setup.character.id, 'innkeeper');
    expect(setup.number, 1);
    expect(setup.event, isNull);
    expect(setup.intro, ['객잔 주인 첫 만남']);
    expect(Relationship.values, contains(setup.relationship));
    expect(setup.frames, hasLength(4));
    expect(setup.frames.map((f) => f.frame.id).toSet(), hasLength(4));
    final qs = StoryComposer.questions(_world, text, setup);
    expect(qs, hasLength(4));
    for (final q in qs) {
      expect(q.choices, hasLength(3));
      expect(q.text, isNot(contains('{')));
      expect(q.text, isNot(startsWith('story.')));
    }
  });

  test('판단과 만남 기록은 대사 생성 전에 저장된다', () async {
    final log = <String>[];
    final story = _LoggedStory(log);
    final acc = _LoggedAccumulation(log);
    final engine = _Engine(log: log);
    final setup = await start(story, 1);
    final plan = await planWith(story, acc, setup, ['c1', 'c1', 'c1', 'c1']);

    expect(log, ['story', 'accumulation']);
    final saved = story.meetings['mini']!.single;
    expect(saved, plan.meeting);
    expect(saved.number, 1);
    expect(saved.characterId, 'innkeeper');
    expect(saved.relationship, setup.relationship);
    expect(saved.at, now);
    expect(saved.answers.map((a) => a.frameId), [
      for (final f in setup.frames) f.frame.id,
    ]);
    expect(saved.answers.map((a) => a.variant), [
      for (final f in setup.frames) f.variant,
    ]);

    final attempt = acc.state.attempts.single;
    expect(attempt, plan.attemptPlan.attempt);
    expect(attempt.index, 1);
    expect(attempt.channelId, 'story.mini');
    expect(attempt.archetype, 0);
    expect(attempt.theoryId, 'bigfive');
    expect(attempt.at, now);
    expect(attempt.answers, [
      for (final a in saved.answers)
        Answer(questionId: a.frameId, choiceId: a.choiceId),
    ]);
    expect(plan.attemptPlan.channelId, 'story.mini');
    expect(plan.attemptPlan.reading, isNull);
    expect(plan.attemptPlan.deepReading, isNull);

    await ComposeMeetingUseCase(engine, Random(1))(
      world: _world,
      text: text,
      plan: plan,
    );
    expect(log, ['story', 'accumulation', 'engine']);
  });

  test('같은 인물을 다시 만나면 이전 판단에서 이어진다', () async {
    final story = InMemoryStoryRepository();
    final acc = InMemoryAccumulationRepository();
    final first = await planWith(story, acc, await start(story, 1), [
      'c1',
      'c1',
      'c1',
      'c1',
    ]);
    expect(first.judgment.outcome, 'C+');
    expect(first.judgment.tone, JudgmentTone.first);
    expect(first.pastAnswer, isNull);

    final again = await start(story, 2);
    expect(again.character.id, 'innkeeper');
    expect(again.relationship, first.meeting.relationship);
    expect(again.number, 2);
    expect(again.intro, ['객잔 주인 다시 만남 ${first.meeting.relationship.index}']);
    // bigfive 틀은 4개뿐이라 같은 틀이 다시 나온다 (연결 문장이 붙음).
    expect(again.frames.every((f) => f.recallChoiceId == 'c1'), isTrue);
    // C- 1개 + 중립 3개: 누적 C+ 4 대 C- 1 이라 판단은 유지, 이번 답만 보면 C- 라 의외.
    final second = await planWith(story, acc, again, ['c2', 'c3', 'c3', 'c3']);
    expect(second.judgment.outcome, 'C+');
    expect(second.judgment.tone, JudgmentTone.surprised);
    expect(second.meeting.number, 2);
    expect(second.meeting.relationship, first.meeting.relationship);
    expect(second.pastAnswer, isNotNull);
    expect(first.meeting.answers, contains(second.pastAnswer));

    final engine = _Engine();
    await ComposeMeetingUseCase(engine, Random(1))(
      world: _world,
      text: text,
      plan: second,
    );
    final rel = first.meeting.relationship.index;
    expect(engine.bases.single.context, [
      '관계 문장 $rel',
      '흐름 문장 ${JudgmentTone.surprised.index}',
      startsWith('지난번 근거 선택 '),
    ]);
  });

  test('기존 무협 시행 기록은 이야기 기록에 섞이지 않는다', () async {
    final story = InMemoryStoryRepository();
    final acc = InMemoryAccumulationRepository(
      AccumulationState(attempts: [for (var i = 1; i <= 5; i++) attempt(i)]),
    );
    final setup = await start(story, 1);
    expect(setup.character.id, 'innkeeper');
    expect(setup.intro, ['객잔 주인 첫 만남']);

    final plan = await planWith(story, acc, setup, ['c1', 'c1', 'c1', 'c1']);
    // 판단 이력이 비어 있어 이번 답만 센다.
    expect(plan.judgment.tone, JudgmentTone.first);
    expect(plan.judgment.tally, {'C+': 4.0});
    expect(plan.rumorSourceId, isNull);
    expect(plan.attemptPlan.attempt.index, 6);

    // 기존 시행은 발현 재료 후보로 남는다.
    final pool = MaterialSelector.attemptPool(acc.state.attempts);
    expect(pool.where((m) => m.channelId == 'wuxia'), hasLength(10));
    expect(pool.where((m) => m.channelId == 'story.mini'), hasLength(4));
  });

  test('발현이면 발현 요청을 보내고 장면에 섞는다', () async {
    final story = InMemoryStoryRepository();
    final acc = InMemoryAccumulationRepository(
      AccumulationState(attempts: [attempt(1)], gaugePermille: 1000),
    );
    final plan = await planWith(story, acc, await start(story, 1), [
      'c1',
      'c1',
      'c1',
      'c1',
    ]);
    expect(plan.attemptPlan.manifested, isTrue);
    expect(acc.state.manifestations.single, plan.attemptPlan.manifestation);

    final engine = _Engine();
    final r = await ComposeMeetingUseCase(engine, Random(1))(
      world: _world,
      text: text,
      plan: plan,
    );
    expect(engine.manifests.single.speaker, '객잔 주인');
    expect(r.manifested, isTrue);
    expect(r.scenes.expand((s) => s.lines), contains('발현 1'));
  });

  test('모델이 실패하면 프로필 3줄로 결과를 만든다', () async {
    final story = InMemoryStoryRepository();
    final acc = InMemoryAccumulationRepository();
    final plan = await planWith(story, acc, await start(story, 1), [
      'c1',
      'c1',
      'c1',
      'c1',
    ]);
    final r = await ComposeMeetingUseCase(_Engine(fail: true), Random(1))(
      world: _world,
      text: text,
      plan: plan,
    );
    // bigfive 결과 순서 O+, O-, C+ 에서 C+ 는 2번, bigfive 는 0번 이론.
    expect(r.scenes.single.lines, [
      '객잔 주인 왈 너는 객잔 주인 칭호 2',
      '유형 0-2 설명',
      '유형 0-2 장점',
      '유형 0-2 약점',
      '객잔 주인 맺음 2',
    ]);
    expect(r.baseSource, NarrationSource.template);
    expect(r.channelId, 'story.mini');
  });

  test('선택지 수가 틀과 다르거나 없는 선택지면 저장하지 않고 실패', () async {
    final story = InMemoryStoryRepository();
    final acc = InMemoryAccumulationRepository();
    final setup = await start(story, 1);
    for (final ids in [
      ['c1'],
      ['c1', 'c1', 'c1', 'zz'],
    ]) {
      final r = await PlanMeetingUseCase(story, acc, Random(1), () => now)(
        world: _world,
        setup: setup,
        choiceIds: ids,
      );
      expect(r.failureOrNull, isA<BusinessRuleFailure>());
    }
    expect(story.meetings, isEmpty);
    expect(acc.state.attempts, isEmpty);
  });

  test('이야기 기록 저장이 실패하면 누적도 저장하지 않는다', () async {
    final story = InMemoryStoryRepository()..failAppend = true;
    final acc = InMemoryAccumulationRepository();
    final setup = await start(story, 1);
    final r = await PlanMeetingUseCase(story, acc, Random(1), () => now)(
      world: _world,
      setup: setup,
      choiceIds: const ['c1', 'c1', 'c1', 'c1'],
    );
    expect(r.failureOrNull, isA<LocalStorageFailure>());
    expect(acc.state.attempts, isEmpty);
  });
}
