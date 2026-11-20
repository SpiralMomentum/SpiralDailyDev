import 'dart:math';

import 'package:utils/utils.dart';

import '../entities/accumulation.dart';
import '../entities/evaluation.dart';
import '../entities/text_book.dart';
import '../policies/accumulation_step.dart';
import '../repositories/accumulation_repository.dart';
import '../repositories/narration_engine.dart';
import 'frame_picker.dart';
import 'story_composer.dart';
import 'story_director.dart';
import 'story_judge.dart';
import 'story_ledger.dart';
import 'story_record.dart';
import 'story_repository.dart';
import 'story_world.dart';

export 'story_composer.dart' show MeetingPlan, MeetingSetup;

/// 오늘 만날 인물, 관계, 사건, 질문, 도입 문장을 정한다. 저장하지 않는다.
class StartMeetingUseCase {
  const StartMeetingUseCase(this._story, this._random);

  final StoryRepository _story;
  final Random _random;

  Future<Result<MeetingSetup>> call(StoryWorld world, TextBook text) async {
    final loaded = await _story.load(world.id);
    return loaded.map((meetings) {
      final ledger = StoryLedger.of(world, meetings);
      final character = StoryDirector.nextCharacter(world, ledger, _random);
      final relationship = StoryDirector.relationshipFor(
        ledger,
        character.id,
        _random,
      );
      final event = StoryDirector.pendingEvent(world, ledger, character.id);
      final frames = FramePicker.pick(world, ledger, character, _random);
      return MeetingSetup(
        character: character,
        relationship: relationship,
        frames: frames,
        intro: StoryComposer.intro(
          world,
          text,
          ledger,
          character,
          relationship,
          event,
          asked: {for (final p in frames) p.frame.id},
        ),
        event: event,
        number: ledger.total + 1,
      );
    });
  }
}

/// 답을 받아 인물의 판단을 확정하고, 만남 기록과 누적 기록을 대사 생성 전에 저장한다.
/// 저장 순서: 이야기 기록 -> 누적. 이야기 기록 저장이 실패하면 누적은 건드리지 않는다.
class PlanMeetingUseCase {
  const PlanMeetingUseCase(
    this._story,
    this._accumulation,
    this._random,
    this._clock,
  );

  final StoryRepository _story;
  final AccumulationRepository _accumulation;
  final Random _random;
  final DateTime Function() _clock;

  Future<Result<MeetingPlan>> call({
    required StoryWorld world,
    required MeetingSetup setup,
    required List<String> choiceIds,
  }) async {
    final character = setup.character;
    final theory = world.theoryById(character.theoryId);
    if (theory == null) {
      return ErrorResult(
        BusinessRuleFailure(message: 'theory:${character.theoryId}'),
      );
    }
    final picked = _choices(setup.frames, choiceIds);
    if (picked == null) {
      return const ErrorResult(BusinessRuleFailure(message: 'choices'));
    }

    final loaded = await _story.load(world.id);
    if (loaded case ErrorResult(:final failure)) return ErrorResult(failure);
    final ledger = StoryLedger.of(world, loaded.dataOrNull!);
    final state = await _accumulation.load();
    if (state case ErrorResult(:final failure)) return ErrorResult(failure);

    List<WeightedVote> votes(Iterable<StoryAnswer> answers, double weight) => [
      for (final a in answers)
        if (_choiceOf(world, a) case final c?)
          (poles: StoryJudge.poles(theory, c), weight: weight),
    ];

    final answers = [
      for (final (i, p) in setup.frames.indexed)
        StoryAnswer(
          frameId: p.frame.id,
          variant: p.variant,
          choiceId: choiceIds[i],
        ),
    ];
    final judgment = StoryJudge.judge(
      theory,
      history: [
        ...votes(ledger.answersTo(character.id), 1),
        ...votes(ledger.rumorsAbout(character.id), StoryRules.rumorWeight),
      ],
      current: [
        for (final c in picked)
          (poles: StoryJudge.poles(theory, c), weight: 1.0),
      ],
      previous: ledger.lastOutcome(character.id),
    );
    final at = _clock();
    final meeting = StoryMeeting(
      number: ledger.total + 1,
      characterId: character.id,
      relationship: setup.relationship,
      answers: answers,
      outcome: judgment.outcome,
      at: at,
      eventId: setup.event?.id,
    );

    final current = state.dataOrNull!;
    final channelId = StoryComposer.channelId(world);
    final attempt = AttemptRecord(
      index: current.nextAttemptIndex,
      channelId: channelId,
      answers: [
        for (final a in answers)
          Answer(questionId: a.frameId, choiceId: a.choiceId),
      ],
      archetype: 0,
      at: at,
      theoryId: theory.id,
    );
    // 이야기에는 카탈로그가 없으므로 발현 이론 후보는 세계의 이론이다 (같은 id 체계).
    final advance = AccumulationStep.advance(
      current,
      attempt,
      theories: world.theories,
      random: _random,
    );

    final appended = await _story.append(world.id, meeting);
    if (appended case ErrorResult(:final failure)) return ErrorResult(failure);
    final saved = await _accumulation.save(advance.next);
    return saved.map(
      (_) => MeetingPlan(
        setup: setup,
        meeting: meeting,
        judgment: judgment,
        attemptPlan: AttemptPlan(
          channelId: channelId,
          attempt: attempt,
          manifestation: advance.manifestation,
        ),
        pastAnswer: StoryComposer.pastEvidence(
          world,
          ledger,
          character,
          judgment.outcome,
        ),
        rumorSourceId: StoryComposer.rumorSource(ledger, character.id),
        priorAnswerCount: ledger.answersTo(character.id).length,
      ),
    );
  }

  /// 틀마다 고른 선택지. 수가 다르거나 틀에 없는 선택지면 null.
  static List<FrameChoice>? _choices(
    List<PickedFrame> frames,
    List<String> choiceIds,
  ) {
    if (frames.length != choiceIds.length) return null;
    final out = <FrameChoice>[];
    for (final (i, p) in frames.indexed) {
      final c = p.frame.choices.where((c) => c.id == choiceIds[i]).firstOrNull;
      if (c == null) return null;
      out.add(c);
    }
    return out;
  }

  static FrameChoice? _choiceOf(StoryWorld world, StoryAnswer a) => world
      .frameById(a.frameId)
      ?.choices
      .where((c) => c.id == a.choiceId)
      .firstOrNull;
}

/// 확정된 만남으로 결과 장면을 만든다 (모델이 도는, 대기 시간이 생기는 단계).
/// 모델이 실패하면 프로필 3줄, 발현 대사가 실패하면 발현 없이 기본 결과.
class ComposeMeetingUseCase {
  const ComposeMeetingUseCase(this._engine, this._random);

  final NarrationEngine _engine;
  final Random _random;

  Future<EvaluationResult> call({
    required StoryWorld world,
    required TextBook text,
    required MeetingPlan plan,
  }) async {
    final base = await _engine.baseLines(
      StoryComposer.baseRequest(world, text, plan),
      _random,
    );
    final manifest = plan.attemptPlan.manifestation == null
        ? null
        : await _engine.manifestation(
            StoryComposer.manifestationRequest(world, text, plan),
            _random,
          );
    return StoryComposer.result(
      world: world,
      text: text,
      plan: plan,
      base: base.dataOrNull,
      manifest: manifest?.dataOrNull,
    );
  }
}
