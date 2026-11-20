import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/catalog.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/evaluation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/quiz_question.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/text_book.dart';
import 'package:self_eval_sim/features/simulation/domain/repositories/narration_engine.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_use_cases.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_world.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/compose_result_use_case.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/extend_result_use_case.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/plan_attempt_use_case.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/start_attempt_use_case.dart';
import 'package:self_eval_sim/features/simulation/presentation/flow/attempt_flow.dart';
import 'package:self_eval_sim/features/simulation/presentation/flow/story_flow.dart';
import 'package:utils/utils.dart';

import '../../../support/fixtures.dart';
import '../../../support/story_fixtures.dart';

/// 대체 문장을 그대로 돌려주는 엔진.
class _Engine implements NarrationEngine {
  @override
  Future<Result<Narration>> baseLines(
    BaseNarrationRequest request,
    Random random,
  ) async => Success(
    Narration(lines: request.fallbackLines, source: NarrationSource.template),
  );

  @override
  Future<Result<ManifestationText>> manifestation(
    ManifestationRequest request,
    Random random,
  ) async => const Success(
    ManifestationText(
      lines: ['기억 줄'],
      separateSpeaker: '목소리',
      separatePlace: '공허',
    ),
  );
}

/// 수동으로 완료시키는 저장소: 계획 도중 두 번째 호출이 들어오는 상황을 만든다.
class _SlowStory extends InMemoryStoryRepository {
  var appends = 0;

  @override
  Future<Result<void>> append(String worldId, meeting) async {
    appends++;
    await Future<void>.delayed(Duration.zero);
    return super.append(worldId, meeting);
  }
}

class _Flow implements AttemptFlow {
  _Flow(this.name);

  final String name;

  @override
  String get art => name;

  @override
  Future<Result<({List<String> intro, List<QuizQuestion> questions})>>
  start() async =>
      const Success((intro: <String>[], questions: <QuizQuestion>[]));

  @override
  Future<Result<bool>> plan(List<String> choiceIds) async =>
      const Success(false);

  @override
  Future<EvaluationResult> compose() => throw UnimplementedError();

  @override
  EvaluationResult extend(EvaluationResult result) => result;
}

void main() {
  final now = DateTime.utc(2026, 11, 20);

  group('ChannelFlow', () {
    final channel = testChannel(questions: 2);
    final content = LocalizedContent(
      catalog: ContentCatalog(channels: [channel], questionsPerAttempt: 2),
      text: testText(),
    );

    ChannelFlow flow(InMemoryAccumulationRepository repo) => ChannelFlow(
      channel,
      content,
      StartAttemptUseCase(Random(1)),
      PlanAttemptUseCase(repo, ScriptedRandom(bools: [false]), () => now),
      ComposeResultUseCase(_Engine(), Random(1)),
      const ExtendResultUseCase(),
    );

    test('문항을 채널 문장으로 풀고 도입은 비어 있다', () async {
      final f = flow(InMemoryAccumulationRepository());
      expect(f.art, channel.art);
      final started = (await f.start()).dataOrNull!;
      expect(started.intro, isEmpty);
      expect(started.questions, hasLength(2));
      final q = started.questions.first;
      final source = channel.questions.firstWhere((s) => s.id == q.id);
      expect(q.text, testText().question(channel.id, q.id));
      expect(q.choices.map((c) => c.id), source.choices.map((c) => c.id));
      expect(
        q.choices.first.text,
        testText().choice(channel.id, q.id, source.choices.first.id),
      );
    });

    test('발현이면 보상 광고 제안 (기존 동작 유지)', () async {
      final repo = InMemoryAccumulationRepository(
        AccumulationState(attempts: [attempt(1)], gaugePermille: 1000),
      );
      final f = flow(repo);
      final qs = (await f.start()).dataOrNull!.questions;
      final offer = await f.plan([for (final q in qs) q.choices.first.id]);
      expect(repo.state.manifestations, hasLength(1));
      expect(offer.dataOrNull, isTrue);
    });

    test('계획 -> 결과 -> 확장. 계획은 한 시행에 한 번만 저장한다', () async {
      final repo = InMemoryAccumulationRepository();
      final f = flow(repo);
      final qs = (await f.start()).dataOrNull!.questions;
      final ids = [for (final q in qs) q.choices.first.id];
      final results = await Future.wait([f.plan(ids), f.plan(ids)]);
      expect(results.map((r) => r.dataOrNull), [false, false]);
      expect(repo.state.attempts, hasLength(1));
      expect(
        repo.state.attempts.single.answers.map((a) => a.questionId),
        qs.map((q) => q.id),
      );
      final composed = await f.compose();
      expect(composed.channelId, channel.id);
      final extended = f.extend(composed);
      expect(extended.extended, isTrue);
      expect(extended.scenes.last.kind, SceneKind.extension);
    });
  });

  group('StoryFlow', () {
    final text = storyTextFor(quizWorld);
    final content = LocalizedContent(
      catalog: testCatalog(),
      text: text,
      stories: {'wuxia': quizWorld},
    );

    StoryFlow flow(
      InMemoryStoryRepository story,
      InMemoryAccumulationRepository acc, {
      LocalizedContent? localized,
    }) => StoryFlow(
      quizWorld,
      localized ?? content,
      StartMeetingUseCase(story, Random(3)),
      PlanMeetingUseCase(story, acc, ScriptedRandom(bools: [false]), () => now),
      ComposeMeetingUseCase(_Engine(), Random(3)),
      channelArt: 'channel_art',
    );

    test('인물 배경이 없으면 채널 배경을 쓴다 (시작 전에도 채널 배경)', () async {
      final noArt = LocalizedContent(
        catalog: content.catalog,
        text: TextBook(
          languageCode: 'ko',
          entries: {
            for (final e in text.entries.entries)
              if (!e.key.endsWith('.art')) e.key: e.value,
          },
        ),
        stories: content.stories,
      );
      final f = flow(
        InMemoryStoryRepository(),
        InMemoryAccumulationRepository(),
        localized: noArt,
      );
      expect(f.art, 'channel_art');
      await f.start();
      expect(f.art, 'channel_art');
    });

    test('발현한 만남이어도 보상 광고를 제안하지 않는다 (확장 장면 없음)', () async {
      final acc = InMemoryAccumulationRepository(
        AccumulationState(attempts: [attempt(1)], gaugePermille: 1000),
      );
      final f = flow(InMemoryStoryRepository(), acc);
      final qs = (await f.start()).dataOrNull!.questions;
      final offer = await f.plan([for (final _ in qs) 'c1']);
      expect(acc.state.manifestations, hasLength(1));
      expect(offer.dataOrNull, isFalse);
    });

    test('첫 만남: 도입 문장과 풀린 4문항, 인물 배경', () async {
      final f = flow(
        InMemoryStoryRepository(),
        InMemoryAccumulationRepository(),
      );
      final started = (await f.start()).dataOrNull!;
      expect(started.intro, ['객잔 주인 첫 만남']);
      expect(started.questions, hasLength(4));
      expect(started.questions.first.text, startsWith('질문 '));
      expect(started.questions.first.choices.first.text, startsWith('선택 '));
      expect(f.art, 'innkeeper_art');
    });

    test('계획은 같은 준비로 두 번 하지 않는다 (동시 호출도 한 번 저장)', () async {
      final story = _SlowStory();
      final acc = InMemoryAccumulationRepository();
      final f = flow(story, acc);
      final qs = (await f.start()).dataOrNull!.questions;
      final ids = [for (final _ in qs) 'c1'];
      final results = await Future.wait([f.plan(ids), f.plan(ids)]);
      expect(results.map((r) => r.isSuccess), [true, true]);
      expect(story.appends, 1);
      expect(story.meetings[quizWorld.id], hasLength(1));
      expect(acc.state.attempts, hasLength(1));
      expect(await f.plan(ids), results.first);
      expect(story.appends, 1);
    });

    test('계획 실패 후에도 다시 계획하지 않는다', () async {
      final story = InMemoryStoryRepository()..failAppend = true;
      final f = flow(story, InMemoryAccumulationRepository());
      final qs = (await f.start()).dataOrNull!.questions;
      final ids = [for (final _ in qs) 'c1'];
      expect((await f.plan(ids)).isError, isTrue);
      story.failAppend = false;
      expect((await f.plan(ids)).isError, isTrue);
      expect(story.meetings, isEmpty);
    });

    test('결과 장면, 확장은 그대로', () async {
      final f = flow(
        InMemoryStoryRepository(),
        InMemoryAccumulationRepository(),
      );
      final qs = (await f.start()).dataOrNull!.questions;
      await f.plan([for (final _ in qs) 'c1']);
      final composed = await f.compose();
      expect(composed.scenes.first.speaker, '객잔 주인');
      expect(f.extend(composed), same(composed));
    });

    test('계획 전 결과 요청은 상태 오류', () async {
      final f = flow(
        InMemoryStoryRepository(),
        InMemoryAccumulationRepository(),
      );
      await f.start();
      expect(f.compose, throwsStateError);
    });
  });

  group('AttemptFlows.select', () {
    final channel = testChannel();
    final other = testChannel(id: 'gem');
    final content = LocalizedContent(
      catalog: ContentCatalog(
        channels: [channel, other],
        questionsPerAttempt: 2,
      ),
      text: TextBook(languageCode: 'ko', entries: const {}),
      stories: {'wuxia': quizWorld},
    );

    AttemptFlow pick(Channel c) => AttemptFlows.select(
      channel: c,
      content: content,
      channelFlow: () => _Flow('channel'),
      storyFlow: (StoryWorld w, Channel c) => _Flow('story:${w.id}:${c.art}'),
    )();

    test('이야기가 있으면 이야기 흐름, 없으면 채널 흐름', () {
      expect(pick(channel).art, 'story:${quizWorld.id}:${channel.art}');
      expect(pick(other).art, 'channel');
    });
  });
}
