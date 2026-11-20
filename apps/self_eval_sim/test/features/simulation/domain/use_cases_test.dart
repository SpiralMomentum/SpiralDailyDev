import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/catalog.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/evaluation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/text_book.dart';
import 'package:self_eval_sim/features/simulation/domain/repositories/content_repository.dart';
import 'package:self_eval_sim/features/simulation/domain/repositories/narration_engine.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_record.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_repository.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_world.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/compose_result_use_case.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/history_use_cases.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/load_content_use_case.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/plan_attempt_use_case.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/start_attempt_use_case.dart';
import 'package:utils/utils.dart';

import '../../../support/fixtures.dart';
import '../../../support/story_fixtures.dart';

class _EchoEngine implements NarrationEngine {
  _EchoEngine({this.fail = false});

  final bool fail;
  List<ResolvedMaterial>? received;
  BaseNarrationRequest? baseRequest;
  ManifestationRequest? manifestRequest;

  @override
  Future<Result<Narration>> baseLines(
    BaseNarrationRequest request,
    Random random,
  ) async {
    baseRequest = request;
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
    manifestRequest = request;
    received = request.materials;
    if (fail) return const ErrorResult(ParsingFailure(message: 'engine'));
    return Success(
      ManifestationText(
        lines: [for (final m in request.materials) '${m.ago}:${m.choiceText}'],
        separateSpeaker: 'voice',
        separatePlace: 'void',
        source: NarrationSource.model,
      ),
    );
  }
}

class _Content implements ContentRepository {
  _Content({this.failText = false, this.failStory = false});

  final bool failText;
  final bool failStory;
  final storyRequests = <String>[];

  @override
  Future<Result<StoryWorld>> loadStoryWorld(String worldId) async {
    storyRequests.add(worldId);
    return failStory
        ? const ErrorResult(ParsingFailure(message: 'story'))
        : const Success(miniWorld);
  }

  @override
  Future<Result<ContentCatalog>> loadCatalog() async => Success(
    ContentCatalog(channels: [testChannel()], questionsPerAttempt: 2),
  );

  @override
  Future<Result<TextBook>> loadText(String languageCode) async => failText
      ? const ErrorResult(ParsingFailure(message: 'text'))
      : Success(testText(languageCode: languageCode));
}

void main() {
  final channel = testChannel();
  final catalog = testCatalog(channel: channel);
  const answers = [
    Answer(questionId: 'q1', choiceId: 'c2'),
    Answer(questionId: 'q2', choiceId: 'c2'),
  ];
  final now = DateTime.utc(2026, 11, 19);

  group('PlanAttemptUseCase', () {
    test('첫 시행: 확률 0 이라 발현 없음, 기록 1건 저장, 확률은 1~100 상승', () async {
      final repo = InMemoryAccumulationRepository();
      final plan = await PlanAttemptUseCase(repo, Random(1), () => now)(
        catalog: catalog,
        channel: channel,
        answers: answers,
      );
      expect(plan.dataOrNull!.manifested, isFalse);
      expect(plan.dataOrNull!.attempt.index, 1);
      expect(plan.dataOrNull!.attempt.archetype, 1);
      expect(repo.state.attempts.single.at, now);
      expect(repo.state.gaugePermille, inInclusiveRange(1, 100));
    });

    test('천장에 닿은 상태면 반드시 발현하고, 발현 기록 저장 후 확률을 0 으로 되돌린다', () async {
      final repo = InMemoryAccumulationRepository(
        AccumulationState(
          attempts: [attempt(1), attempt(2)],
          gaugePermille: 1000,
        ),
      );
      final plan = await PlanAttemptUseCase(repo, Random(1), () => now)(
        catalog: catalog,
        channel: channel,
        answers: answers,
      );
      final m = plan.dataOrNull!.manifestation!;
      expect(m.attemptIndex, 3);
      expect(
        m.materials,
        hasLength(2),
      ); // 과거 발현 없음 -> 시행 재료. 두 시행의 선택이 같아 서로 다른 선택은 2개
      expect(repo.state.manifestations.single, m);
      expect(repo.state.gaugePermille, 0);
    });

    test('발현 형태는 난수로 mixed/separate 중 하나', () async {
      Future<ManifestationForm> formWith(bool b) async {
        final repo = InMemoryAccumulationRepository(
          AccumulationState(attempts: [attempt(1)], gaugePermille: 1000),
        );
        final plan = await PlanAttemptUseCase(
          repo,
          ScriptedRandom(bools: [b]),
          () => now,
        )(catalog: catalog, channel: channel, answers: answers);
        return plan.dataOrNull!.manifestation!.form;
      }

      expect(await formWith(true), ManifestationForm.mixed);
      expect(await formWith(false), ManifestationForm.separate);
    });

    test('누적 재료가 없으면(천장이어도) 발현하지 않는다', () async {
      final repo = InMemoryAccumulationRepository(
        const AccumulationState(gaugePermille: 1000),
      );
      final plan = await PlanAttemptUseCase(repo, Random(1), () => now)(
        catalog: catalog,
        channel: channel,
        answers: answers,
      );
      expect(plan.dataOrNull!.manifested, isFalse);
    });

    test('저장 실패는 Failure 로 돌려준다', () async {
      final repo = InMemoryAccumulationRepository()..failSave = true;
      final plan = await PlanAttemptUseCase(repo, Random(1), () => now)(
        catalog: catalog,
        channel: channel,
        answers: answers,
      );
      expect(plan.failureOrNull, isA<LocalStorageFailure>());
    });

    test('시행 1000회: 발현이 일어나고, 발현 직후 시행은 확률 0% 로 초기화되어 발현하지 않는다', () async {
      final repo = InMemoryAccumulationRepository();
      final useCase = PlanAttemptUseCase(repo, Random(2026), () => now);
      final manifestedAt = <int>[];
      for (var i = 0; i < 1000; i++) {
        final plan = await useCase(
          catalog: catalog,
          channel: channel,
          answers: answers,
        );
        if (plan.dataOrNull!.manifested) {
          manifestedAt.add(plan.dataOrNull!.attempt.index);
        }
      }
      expect(manifestedAt, isNotEmpty);
      for (var i = 1; i < manifestedAt.length; i++) {
        expect(manifestedAt[i] - manifestedAt[i - 1], greaterThan(1));
      }
    });
  });

  group('ComposeResultUseCase', () {
    AttemptPlan manifestPlan() => AttemptPlan(
      channelId: 'wuxia',
      attempt: attempt(6),
      manifestation: ManifestationRecord(
        attemptIndex: 6,
        form: ManifestationForm.separate,
        materials: [
          ref(MaterialKind.attempt, 2, c: 'c3'),
          ref(MaterialKind.manifestation, 4),
        ],
      ),
    );

    test('발현 재료를 언어 문장으로 풀어 엔진에 넘기고 별도 장면으로 붙인다', () async {
      final engine = _EchoEngine();
      final r = await ComposeResultUseCase(engine, Random(1))(
        channel: channel,
        plan: manifestPlan(),
        text: testText(),
        catalog: catalog,
      );
      expect(engine.received!.map((m) => m.ago), [4, 2]);
      expect(engine.manifestRequest!.speaker, 'wuxia-speaker');
      expect(engine.manifestRequest!.form, ManifestationForm.separate);
      expect(engine.manifestRequest!.examples, isEmpty); // 별도 장면: 고정 말투
      expect(r.scenes.last.lines, ['4:wuxia-q1-c3', '2:wuxia-q1-c1']);
      expect(r.manifestationForm, ManifestationForm.separate);
      expect(r.manifestationSource, NarrationSource.model);
    });

    test('기본 결과 대사는 모델 출력, 요청에는 고른 답 문장과 말투 예시 8줄이 들어간다', () async {
      final engine = _EchoEngine();
      final r = await ComposeResultUseCase(engine, Random(1))(
        channel: channel,
        plan: manifestPlan(),
        text: testText(),
        catalog: catalog,
      );
      expect(r.scenes.first.lines, ['wuxia-reveal wuxia-title0', '모델 1', '모델 2', 'wuxia-a0-s1']);
      expect(r.baseSource, NarrationSource.model);
      final req = engine.baseRequest!;
      expect(req.answers.first, ('wuxia-q1', 'wuxia-q1-c1', ''));
      expect(req.examples, hasLength(8));
      expect(req.fallbackLines, ['wuxia-a0-l1', 'wuxia-a0-l2']);
      expect(req.title, 'wuxia-title0');
      expect(req.reveal, 'wuxia-reveal wuxia-title0');
    });

    test('섞임 형태는 채널 화자 말투 예시 8줄을 발현 요청에 넣는다', () async {
      final engine = _EchoEngine();
      final mixed = AttemptPlan(
        channelId: 'wuxia',
        attempt: attempt(6),
        manifestation: ManifestationRecord(
          attemptIndex: 6,
          form: ManifestationForm.mixed,
          materials: [ref(MaterialKind.attempt, 2)],
        ),
      );
      await ComposeResultUseCase(engine, Random(1))(
        channel: channel,
        plan: mixed,
        text: testText(),
        catalog: catalog,
      );
      expect(engine.manifestRequest!.examples, hasLength(8));
    });

    test('엔진 실패 시 콘텐츠 대사의 기본 결과, 발현 없음', () async {
      final r = await ComposeResultUseCase(_EchoEngine(fail: true), Random(1))(
        channel: channel,
        plan: manifestPlan(),
        text: testText(),
        catalog: catalog,
      );
      expect(r.manifested, isFalse);
      expect(r.scenes, hasLength(1));
      expect(r.scenes.single.lines, ['wuxia-reveal wuxia-title0', 'wuxia-a0-l1', 'wuxia-a0-l2', 'wuxia-a0-s1']);
      expect(r.baseSource, NarrationSource.template);
    });
  });

  group('LoadContentUseCase / StartAttemptUseCase / History', () {
    test('카탈로그와 언어 문장을 함께 돌려준다', () async {
      final r = await LoadContentUseCase(_Content())('ja');
      expect(r.dataOrNull!.text.languageCode, 'ja');
      expect(r.dataOrNull!.catalog.questionsPerAttempt, 2);
    });

    test('무협 이야기 세계를 함께 싣고, 없으면 빈 맵', () async {
      final content = _Content();
      final r = await LoadContentUseCase(content)('ko');
      expect(content.storyRequests, ['wuxia']);
      expect(r.dataOrNull!.stories, {'wuxia': miniWorld});
      final missing = await LoadContentUseCase(_Content(failStory: true))('ko');
      expect(missing.dataOrNull!.stories, isEmpty);
    });

    test('문장 로드 실패는 Failure', () async {
      final r = await LoadContentUseCase(_Content(failText: true))('ja');
      expect(r.isError, isTrue);
    });

    test('시행 문항은 설정 수만큼', () {
      expect(
        StartAttemptUseCase(Random(1))(testChannel(questions: 6), 4),
        hasLength(4),
      );
    });

    test('기록 요약과 전체 삭제', () async {
      final repo = InMemoryAccumulationRepository(
        AccumulationState(
          attempts: [attempt(1), attempt(2)],
          manifestations: [
            ManifestationRecord(
              attemptIndex: 2,
              form: ManifestationForm.mixed,
              materials: [ref(MaterialKind.attempt, 1)],
            ),
          ],
        ),
      );
      expect(
        (await GetHistorySummaryUseCase(repo)()).dataOrNull,
        const HistorySummary(attempts: 2, manifestations: 1),
      );
      await ClearHistoryUseCase(repo, _FakeStory())();
      expect(
        (await GetHistorySummaryUseCase(repo)()).dataOrNull,
        const HistorySummary(attempts: 0, manifestations: 0),
      );
    });

    test('기록 전체 삭제는 이야기 기록도 지운다', () async {
      final acc = InMemoryAccumulationRepository(
        AccumulationState(attempts: [attempt(1)]),
      );
      final story = _FakeStory();
      final r = await ClearHistoryUseCase(acc, story)();
      expect(r.isSuccess, isTrue);
      expect(story.clearCalls, 1);
      expect(acc.state, AccumulationState.empty);
    });

    test('이야기 삭제가 실패해도 누적 기록은 지우고, 결과는 실패', () async {
      final acc = InMemoryAccumulationRepository(
        AccumulationState(attempts: [attempt(1)]),
      );
      final r = await ClearHistoryUseCase(acc, _FakeStory(fail: true))();
      expect(r.isSuccess, isFalse);
      expect(acc.state, AccumulationState.empty);
    });
  });
}

class _FakeStory implements StoryRepository {
  _FakeStory({this.fail = false});

  final bool fail;
  int clearCalls = 0;

  @override
  Future<Result<void>> clear() async {
    clearCalls++;
    return fail
        ? const ErrorResult(LocalStorageFailure(message: 'story'))
        : const Success(null);
  }

  @override
  Future<Result<List<StoryMeeting>>> load(String worldId) async =>
      const Success([]);

  @override
  Future<Result<void>> append(String worldId, StoryMeeting meeting) async =>
      const Success(null);
}
