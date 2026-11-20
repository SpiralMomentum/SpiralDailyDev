import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/evaluation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/quiz_question.dart';
import 'package:self_eval_sim/features/simulation/presentation/bloc/attempt_bloc.dart';
import 'package:self_eval_sim/features/simulation/presentation/bloc/attempt_event.dart';
import 'package:self_eval_sim/features/simulation/presentation/bloc/attempt_state.dart';
import 'package:self_eval_sim/features/simulation/presentation/flow/attempt_flow.dart';
import 'package:utils/utils.dart';

const _questions = [
  QuizQuestion(
    id: 'q1',
    text: '질문 1',
    choices: [
      QuizChoice(id: 'c1', text: '선택 1'),
      QuizChoice(id: 'c2', text: '선택 2'),
    ],
  ),
  QuizQuestion(
    id: 'q2',
    text: '질문 2',
    choices: [
      QuizChoice(id: 'c1', text: '선택 1'),
      QuizChoice(id: 'c2', text: '선택 2'),
    ],
  ),
];

final _base = EvaluationResult(
  channelId: 'wuxia',
  attemptIndex: 1,
  archetype: 0,
  title: 't',
  scenes: const [
    Scene(
      kind: SceneKind.base,
      art: 'wuxia',
      place: 'p',
      speaker: 's',
      lines: ['a'],
    ),
  ],
);

/// 손으로 쓴 흐름. 호출 기록을 남긴다.
class _FakeFlow implements AttemptFlow {
  _FakeFlow({
    this.intro = const [],
    this.startResult,
    this.planResult = const Success(false),
    this.startGate,
  });

  /// 있으면 시작이 이 값이 완료될 때까지 기다린다.
  final Future<void>? startGate;

  final List<String> intro;
  final Result<({List<String> intro, List<QuizQuestion> questions})>?
  startResult;
  final Result<bool> planResult;
  final planCalls = <List<String>>[];
  var composeCalls = 0;
  var extendCalls = 0;

  @override
  String get art => 'fake_art';

  @override
  Future<Result<({List<String> intro, List<QuizQuestion> questions})>>
  start() async {
    await startGate;
    return startResult ?? Success((intro: intro, questions: _questions));
  }

  @override
  Future<Result<bool>> plan(List<String> choiceIds) async {
    planCalls.add(choiceIds);
    return planResult;
  }

  @override
  Future<EvaluationResult> compose() async {
    composeCalls++;
    return _base;
  }

  @override
  EvaluationResult extend(EvaluationResult result) {
    extendCalls++;
    return result.copyWith(
      scenes: [
        ...result.scenes,
        const Scene(
          kind: SceneKind.extension,
          art: 'fake_art',
          place: 'ext',
          speaker: 's',
          lines: ['e'],
        ),
      ],
      extended: true,
    );
  }
}

void main() {
  late List<_FakeFlow> flows;
  late _FakeFlow Function() nextFlow;
  late List<bool> offerAsked;
  late bool adRewarded;
  late bool adFails;
  late void Function() gateOpener;

  setUp(() {
    flows = [];
    nextFlow = _FakeFlow.new;
    offerAsked = [];
    adRewarded = true;
    adFails = false;
  });

  AttemptBloc build({bool online = true}) => AttemptBloc(
    createFlow: () {
      final f = nextFlow();
      flows.add(f);
      return f;
    },
    decideAdOffer: ({required manifested}) async {
      offerAsked.add(manifested);
      return manifested && online;
    },
    showRewardedAd: () async => adFails
        ? const ErrorResult(NetworkFailure(message: 'ad'))
        : Success(adRewarded),
  );

  /// 문항이 실린 뒤 답을 고른다 (시작은 비동기).
  Future<void> startAndAnswer(AttemptBloc c, List<String> ids) async {
    c.add(const AttemptStarted());
    await c.stream.firstWhere((s) => s.questions.isNotEmpty);
    for (final id in ids) {
      c.add(ChoiceSelected(id));
    }
  }

  blocTest<AttemptBloc, AttemptState>(
    'start: 흐름의 문항과 배경을 받아 quiz 상태',
    build: build,
    act: (c) => c.add(const AttemptStarted()),
    expect: () => [const AttemptState(art: 'fake_art', questions: _questions)],
  );

  blocTest<AttemptBloc, AttemptState>(
    'start 의 intro 가 상태에 실린다',
    setUp: () => nextFlow = () => _FakeFlow(intro: ['도입 1', '도입 2']),
    build: build,
    act: (c) => c.add(const AttemptStarted()),
    expect: () => [
      const AttemptState(
        art: 'fake_art',
        intro: ['도입 1', '도입 2'],
        questions: _questions,
      ),
    ],
  );

  blocTest<AttemptBloc, AttemptState>(
    'start 실패: failure 상태',
    setUp: () => nextFlow = () => _FakeFlow(
      startResult: const ErrorResult(LocalStorageFailure(message: 'load')),
    ),
    build: build,
    act: (c) => c.add(const AttemptStarted()),
    expect: () => [
      const AttemptState(phase: AttemptPhase.failure, errorMessage: 'load'),
    ],
  );

  blocTest<AttemptBloc, AttemptState>(
    '발현 없음: 마지막 답 -> generating -> result (광고 제안 없음)',
    build: build,
    act: (c) => startAndAnswer(c, ['c1', 'c2']),
    skip: 1,
    expect: () => [
      isA<AttemptState>().having((s) => s.answers, 'answers', ['c1']),
      isA<AttemptState>().having((s) => s.answers, 'answers', ['c1', 'c2']),
      isA<AttemptState>().having(
        (s) => s.phase,
        'phase',
        AttemptPhase.generating,
      ),
      isA<AttemptState>()
          .having((s) => s.phase, 'phase', AttemptPhase.result)
          .having((s) => s.result, 'result', _base)
          .having((s) => s.adStatus, 'ad', AdStatus.none),
    ],
    verify: (_) {
      expect(offerAsked, [false]);
      expect(flows.single.planCalls, [
        ['c1', 'c2'],
      ]);
      expect(flows.single.composeCalls, 1);
    },
  );

  blocTest<AttemptBloc, AttemptState>(
    '발현 + 온라인: 광고 제안 -> 시청 완료 -> 확장된 결과',
    setUp: () => nextFlow = () => _FakeFlow(planResult: const Success(true)),
    build: build,
    act: (c) async {
      await startAndAnswer(c, ['c1', 'c2']);
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
          .having(
            (s) => s.result!.scenes.last.kind,
            'last',
            SceneKind.extension,
          ),
    ],
    verify: (_) => expect(flows.single.extendCalls, 1),
  );

  blocTest<AttemptBloc, AttemptState>(
    '보상 제안이 없는 흐름(이야기)은 온라인이어도 광고를 제안하지 않는다',
    // 이야기 흐름은 확장 장면이 없어 발현해도 plan 이 false(보상 제안 없음)를 돌려준다.
    setUp: () => nextFlow = () => _FakeFlow(planResult: const Success(false)),
    build: build,
    act: (c) => startAndAnswer(c, ['c1', 'c2']),
    expect: () => [
      isA<AttemptState>(),
      isA<AttemptState>(),
      isA<AttemptState>(),
      isA<AttemptState>(),
      isA<AttemptState>()
          .having((s) => s.phase, 'phase', AttemptPhase.result)
          .having((s) => s.adStatus, 'ad', AdStatus.none),
    ],
    verify: (b) {
      expect(offerAsked, [false]);
      expect(flows.single.extendCalls, 0);
    },
  );

  blocTest<AttemptBloc, AttemptState>(
    '광고를 중간에 닫으면 보상 없이 결과',
    setUp: () {
      nextFlow = () => _FakeFlow(planResult: const Success(true));
      adRewarded = false;
    },
    build: build,
    act: (c) async {
      await startAndAnswer(c, ['c1', 'c2']);
      await c.stream.firstWhere((s) => s.adStatus == AdStatus.offered);
      c.add(const AdWatchRequested());
    },
    skip: 6,
    expect: () => [
      isA<AttemptState>().having((s) => s.adStatus, 'ad', AdStatus.declined),
      isA<AttemptState>().having(
        (s) => s.result!.extended,
        'extended',
        isFalse,
      ),
    ],
    verify: (_) => expect(flows.single.extendCalls, 0),
  );

  blocTest<AttemptBloc, AttemptState>(
    '광고 로드 실패도 결과는 보여 준다',
    setUp: () {
      nextFlow = () => _FakeFlow(planResult: const Success(true));
      adFails = true;
    },
    build: build,
    act: (c) async {
      await startAndAnswer(c, ['c1', 'c2']);
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
    setUp: () => nextFlow = () => _FakeFlow(planResult: const Success(true)),
    build: build,
    act: (c) async {
      await startAndAnswer(c, ['c1', 'c2']);
      await c.stream.firstWhere((s) => s.adStatus == AdStatus.offered);
      c.add(const AdSkipped());
      c.add(const AdWatchRequested());
    },
    skip: 5,
    expect: () => [
      isA<AttemptState>().having((s) => s.adStatus, 'ad', AdStatus.declined),
      isA<AttemptState>().having(
        (s) => s.result!.extended,
        'extended',
        isFalse,
      ),
    ],
  );

  blocTest<AttemptBloc, AttemptState>(
    '발현 + 오프라인: 광고 제안 없이 결과',
    setUp: () => nextFlow = () => _FakeFlow(planResult: const Success(true)),
    build: () => build(online: false),
    act: (c) => startAndAnswer(c, ['c1', 'c2']),
    skip: 4,
    expect: () => [
      isA<AttemptState>()
          .having((s) => s.phase, 'phase', AttemptPhase.result)
          .having((s) => s.adStatus, 'ad', AdStatus.none),
    ],
    verify: (_) => expect(offerAsked, [true]),
  );

  blocTest<AttemptBloc, AttemptState>(
    '계획(기록 저장) 실패: failure 상태, 다시 계획하지 않는다',
    setUp: () => nextFlow = () => _FakeFlow(
      planResult: const ErrorResult(LocalStorageFailure(message: 'disk')),
    ),
    build: build,
    act: (c) async {
      await startAndAnswer(c, ['c1', 'c2']);
      await c.stream.firstWhere((s) => s.phase == AttemptPhase.failure);
      c.add(const ChoiceSelected('c1'));
    },
    skip: 4,
    expect: () => [
      const AttemptState(
        phase: AttemptPhase.failure,
        art: 'fake_art',
        questions: _questions,
        answers: ['c1', 'c2'],
        errorMessage: 'disk',
      ),
    ],
    verify: (_) {
      expect(flows.single.planCalls, hasLength(1));
      expect(flows.single.composeCalls, 0);
    },
  );

  blocTest<AttemptBloc, AttemptState>(
    '광고 제안 전에 온 광고 이벤트는 무시한다',
    setUp: () => nextFlow = () => _FakeFlow(planResult: const Success(true)),
    build: build,
    act: (c) async {
      c.add(const AttemptStarted());
      c.add(const AdWatchRequested());
      await c.stream.firstWhere((s) => s.questions.isNotEmpty);
      c.add(const ChoiceSelected('c1'));
      c.add(const ChoiceSelected('c2'));
    },
    skip: 4,
    expect: () => [
      isA<AttemptState>().having((s) => s.adStatus, 'ad', AdStatus.offered),
    ],
  );

  blocTest<AttemptBloc, AttemptState>(
    '마지막 답 이후 중복 탭은 무시하고 계획은 한 번만 한다',
    build: build,
    act: (c) => startAndAnswer(c, ['c1', 'c2', 'c2', 'c1']),
    skip: 1,
    expect: () => [
      isA<AttemptState>(),
      isA<AttemptState>(),
      isA<AttemptState>(),
      isA<AttemptState>().having((s) => s.phase, 'phase', AttemptPhase.result),
    ],
    verify: (_) {
      expect(flows.single.planCalls, [
        ['c1', 'c2'],
      ]);
      expect(flows.single.composeCalls, 1);
    },
  );

  blocTest<AttemptBloc, AttemptState>(
    '문항이 실리기 전의 선택은 무시한다',
    setUp: () {
      final gate = Completer<void>();
      nextFlow = () => _FakeFlow(startGate: gate.future);
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      gateOpener = gate.complete;
    },
    build: build,
    act: (c) async {
      c.add(const AttemptStarted());
      c.add(const ChoiceSelected('c1'));
      await Future<void>.delayed(Duration.zero);
      gateOpener();
    },
    expect: () => [const AttemptState(art: 'fake_art', questions: _questions)],
  );

  blocTest<AttemptBloc, AttemptState>(
    '한 번 더: 새 흐름을 만들어 처음부터 (이전 계획을 다시 쓰지 않음)',
    build: build,
    act: (c) async {
      await startAndAnswer(c, ['c1', 'c2']);
      await c.stream.firstWhere((s) => s.phase == AttemptPhase.result);
      c.add(const AttemptStarted());
      await c.stream.firstWhere(
        (s) => s.phase == AttemptPhase.quiz && s.questions.isNotEmpty,
      );
    },
    skip: 5,
    expect: () => [
      const AttemptState(),
      const AttemptState(art: 'fake_art', questions: _questions),
    ],
    verify: (_) {
      expect(flows, hasLength(2));
      expect(flows.first.planCalls, hasLength(1));
      expect(flows.last.planCalls, isEmpty);
    },
  );
}
