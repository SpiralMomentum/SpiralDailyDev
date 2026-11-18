import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart' hide Answer;
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/catalog.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/evaluation.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/compose_result_use_case.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/extend_result_use_case.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/plan_attempt_use_case.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/start_attempt_use_case.dart';
import 'package:self_eval_sim/features/simulation/presentation/bloc/attempt_bloc.dart';
import 'package:self_eval_sim/features/simulation/presentation/bloc/attempt_event.dart';
import 'package:self_eval_sim/features/simulation/presentation/bloc/attempt_state.dart';
import 'package:utils/utils.dart';

import '../../../support/fixtures.dart';

class _Start extends Mock implements StartAttemptUseCase {}

class _Plan extends Mock implements PlanAttemptUseCase {}

class _Compose extends Mock implements ComposeResultUseCase {}


void main() {
  setUpAll(() {
    registerFallbackValue(testChannel());
    registerFallbackValue(AttemptPlan(channelId: 'x', attempt: attempt(1), manifestation: null));
    registerFallbackValue(testText());
  });

  final channel = testChannel(questions: 2);
  final content = LocalizedContent(
    catalog: ContentCatalog(channels: [channel], questionsPerAttempt: 2),
    text: testText(),
  );
  final base = EvaluationResult(
    channelId: 'wuxia',
    attemptIndex: 1,
    archetype: 0,
    title: 't',
    scenes: const [Scene(kind: SceneKind.base, art: 'wuxia', place: 'p', speaker: 's', lines: ['a'])],
  );
  AttemptPlan plan({bool manifested = false}) => AttemptPlan(
        channelId: 'wuxia',
        attempt: attempt(1),
        manifestation: manifested
            ? ManifestationRecord(attemptIndex: 1, form: ManifestationForm.mixed, materials: [ref(MaterialKind.attempt, 1)])
            : null,
      );

  late _Start start;
  late _Plan planUseCase;
  late _Compose compose;
  late List<bool> offerAsked;
  late bool adRewarded;
  late bool adFails;

  setUp(() {
    start = _Start();
    planUseCase = _Plan();
    compose = _Compose();
    offerAsked = [];
    adRewarded = true;
    adFails = false;
    when(() => start(any(), any())).thenReturn(channel.questions);
    when(() => compose(channel: any(named: 'channel'), plan: any(named: 'plan'), text: any(named: 'text')))
        .thenAnswer((_) async => base);
  });

  AttemptBloc build({bool online = true}) => AttemptBloc(
        channel: channel,
        content: content,
        startAttempt: start,
        planAttempt: planUseCase,
        composeResult: compose,
        extendResult: const ExtendResultUseCase(),
        decideAdOffer: ({required manifested}) async {
          offerAsked.add(manifested);
          return manifested && online;
        },
        showRewardedAd: () async =>
            adFails ? const ErrorResult(NetworkFailure(message: 'ad')) : Success(adRewarded),
      );

  void stubPlan(Result<AttemptPlan> r) =>
      when(() => planUseCase(channel: any(named: 'channel'), answers: any(named: 'answers')))
          .thenAnswer((_) async => r);

  blocTest<AttemptBloc, AttemptState>(
    'start: 문항을 받아 quiz 상태',
    build: build,
    act: (c) => c.add(const AttemptStarted()),
    expect: () => [AttemptState(questions: channel.questions)],
  );

  blocTest<AttemptBloc, AttemptState>(
    '발현 없음: 마지막 답 -> generating -> result (광고 제안 없음)',
    setUp: () => stubPlan(Success(plan())),
    build: build,
    act: (c) async {
      c.add(const AttemptStarted());
      c.add(const ChoiceSelected('c1'));
      c.add(const ChoiceSelected('c2'));
    },
    skip: 1,
    expect: () => [
      isA<AttemptState>().having((s) => s.answers.length, 'answers', 1),
      isA<AttemptState>().having((s) => s.answers.length, 'answers', 2),
      isA<AttemptState>().having((s) => s.phase, 'phase', AttemptPhase.generating),
      isA<AttemptState>()
          .having((s) => s.phase, 'phase', AttemptPhase.result)
          .having((s) => s.result, 'result', base)
          .having((s) => s.adStatus, 'ad', AdStatus.none),
    ],
    verify: (_) => expect(offerAsked, [false]),
  );

  blocTest<AttemptBloc, AttemptState>(
    '발현 + 온라인: 광고 제안 -> 시청 완료 -> 확장된 결과',
    setUp: () => stubPlan(Success(plan(manifested: true))),
    build: build,
    act: (c) async {
      c.add(const AttemptStarted());
      c.add(const ChoiceSelected('c1'));
      c.add(const ChoiceSelected('c2'));
      await c.stream.firstWhere((s) => s.adStatus == AdStatus.offered);
      c.add(const AdWatchRequested());
    },
    skip: 4,
    expect: () => [
      isA<AttemptState>().having((s) => s.adStatus, 'ad', AdStatus.offered),
      isA<AttemptState>().having((s) => s.adStatus, 'ad', AdStatus.watching),
      isA<AttemptState>().having((s) => s.adStatus, 'ad', AdStatus.rewarded),
      isA<AttemptState>()
          .having((s) => s.phase, 'phase', AttemptPhase.result)
          .having((s) => s.result!.extended, 'extended', isTrue)
          .having((s) => s.result!.scenes.last.kind, 'last', SceneKind.extension),
    ],
  );

  blocTest<AttemptBloc, AttemptState>(
    '광고를 중간에 닫으면 보상 없이 결과',
    setUp: () {
      stubPlan(Success(plan(manifested: true)));
      adRewarded = false;
    },
    build: build,
    act: (c) async {
      c.add(const AttemptStarted());
      c.add(const ChoiceSelected('c1'));
      c.add(const ChoiceSelected('c2'));
      await c.stream.firstWhere((s) => s.adStatus == AdStatus.offered);
      c.add(const AdWatchRequested());
    },
    skip: 6,
    expect: () => [
      isA<AttemptState>().having((s) => s.adStatus, 'ad', AdStatus.declined),
      isA<AttemptState>().having((s) => s.result!.extended, 'extended', isFalse),
    ],
  );

  blocTest<AttemptBloc, AttemptState>(
    '광고 로드 실패도 결과는 보여 준다',
    setUp: () {
      stubPlan(Success(plan(manifested: true)));
      adFails = true;
    },
    build: build,
    act: (c) async {
      c.add(const AttemptStarted());
      c.add(const ChoiceSelected('c1'));
      c.add(const ChoiceSelected('c2'));
      await c.stream.firstWhere((s) => s.adStatus == AdStatus.offered);
      c.add(const AdWatchRequested());
    },
    skip: 6,
    expect: () => [
      isA<AttemptState>().having((s) => s.adStatus, 'ad', AdStatus.failed),
      isA<AttemptState>().having((s) => s.phase, 'phase', AttemptPhase.result),
    ],
  );

  blocTest<AttemptBloc, AttemptState>(
    '광고 건너뛰기: declined -> 확장 없는 결과, 이후 watchAd 는 무시',
    setUp: () => stubPlan(Success(plan(manifested: true))),
    build: build,
    act: (c) async {
      c.add(const AttemptStarted());
      c.add(const ChoiceSelected('c1'));
      c.add(const ChoiceSelected('c2'));
      await c.stream.firstWhere((s) => s.adStatus == AdStatus.offered);
      c.add(const AdSkipped());
      c.add(const AdWatchRequested());
    },
    skip: 5,
    expect: () => [
      isA<AttemptState>().having((s) => s.adStatus, 'ad', AdStatus.declined),
      isA<AttemptState>().having((s) => s.result!.extended, 'extended', isFalse),
    ],
  );

  blocTest<AttemptBloc, AttemptState>(
    '발현 + 오프라인: 광고 제안 없이 결과',
    setUp: () => stubPlan(Success(plan(manifested: true))),
    build: () => build(online: false),
    act: (c) async {
      c.add(const AttemptStarted());
      c.add(const ChoiceSelected('c1'));
      c.add(const ChoiceSelected('c2'));
    },
    skip: 4,
    expect: () => [
      isA<AttemptState>()
          .having((s) => s.phase, 'phase', AttemptPhase.result)
          .having((s) => s.adStatus, 'ad', AdStatus.none),
    ],
    verify: (_) => expect(offerAsked, [true]),
  );

  blocTest<AttemptBloc, AttemptState>(
    '기록 저장 실패: failure 상태',
    setUp: () => stubPlan(const ErrorResult(LocalStorageFailure(message: 'disk'))),
    build: build,
    act: (c) async {
      c.add(const AttemptStarted());
      c.add(const ChoiceSelected('c1'));
      c.add(const ChoiceSelected('c2'));
    },
    skip: 4,
    expect: () => [
      const AttemptState().copyWith(
        phase: AttemptPhase.failure,
        questions: channel.questions,
        answers: const [Answer(questionId: 'q1', choiceId: 'c1'), Answer(questionId: 'q2', choiceId: 'c2')],
        errorMessage: 'disk',
      ),
    ],
  );

  blocTest<AttemptBloc, AttemptState>(
    '광고 제안 전에 온 광고 이벤트는 무시한다',
    setUp: () => stubPlan(Success(plan(manifested: true))),
    build: build,
    act: (c) {
      c.add(const AttemptStarted());
      c.add(const AdWatchRequested());
      c.add(const ChoiceSelected('c1'));
      c.add(const ChoiceSelected('c2'));
    },
    skip: 4,
    expect: () => [isA<AttemptState>().having((s) => s.adStatus, 'ad', AdStatus.offered)],
  );

  blocTest<AttemptBloc, AttemptState>(
    'quiz 가 아닐 때 선택 이벤트는 무시',
    setUp: () => stubPlan(Success(plan())),
    build: build,
    act: (c) async {
      c.add(const AttemptStarted());
      c.add(const ChoiceSelected('c1'));
      c.add(const ChoiceSelected('c2'));
      c.add(const ChoiceSelected('c3'));
    },
    skip: 1,
    expect: () => [
      isA<AttemptState>(),
      isA<AttemptState>(),
      isA<AttemptState>(),
      isA<AttemptState>().having((s) => s.phase, 'phase', AttemptPhase.result),
    ],
  );
}
