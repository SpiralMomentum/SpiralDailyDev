import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/data/engine/template_narration_engine.dart';
import 'package:self_eval_sim/features/simulation/data/mappers/accumulation_mapper.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/catalog.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/evaluation.dart';
import 'package:self_eval_sim/features/simulation/domain/policies/personality_scorer.dart';
import 'package:self_eval_sim/features/simulation/domain/policies/result_composer.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/plan_attempt_use_case.dart';

import '../../../support/fixtures.dart';

const bigfive = Theory(
  id: 'bigfive',
  mode: TheoryMode.dominant,
  axes: [
    ['O+', 'O-'],
    ['C+', 'C-'],
    ['E+', 'E-'],
  ],
);
const type16 = Theory(
  id: 'type16',
  mode: TheoryMode.code,
  axes: [
    ['E', 'I'],
    ['S', 'N'],
    ['T', 'F'],
    ['J', 'P'],
  ],
);
const enneagram = Theory(
  id: 'enneagram',
  mode: TheoryMode.dominant,
  axes: [
    ['1'],
    ['5'],
    ['8'],
  ],
);

/// q{n}.c{m}: 빅파이브 [C+, E-, O+][m-1], 16유형 [E S, I N, I T][m-1], 에니어그램 [8, 5, 1][m-1].
Channel taggedChannel() => Channel(
  id: 'wuxia',
  art: 'wuxia',
  archetypeCount: 4,
  questions: [
    for (var q = 1; q <= 4; q++)
      Question(
        id: 'q$q',
        choices: [
          for (var c = 1; c <= 3; c++)
            Choice(
              id: 'c$c',
              archetype: c - 1,
              traits: {
                'bigfive': [
                  ['C+'],
                  ['E-'],
                  ['O+'],
                ][c - 1],
                'type16': [
                  ['E', 'S'],
                  ['I', 'N'],
                  ['I', 'T'],
                ][c - 1],
                'enneagram': [
                  ['8'],
                  ['5'],
                  ['1'],
                ][c - 1],
              },
            ),
        ],
      ),
  ],
);

List<Answer> answersOf(List<String> choices) => [
  for (final (i, c) in choices.indexed)
    Answer(questionId: 'q${i + 1}', choiceId: c),
];

void main() {
  group('PersonalityScorer.score', () {
    test('dominant: 순점수(극 - 반대 극)가 가장 높은 극이 유형', () {
      final r = PersonalityScorer.score(bigfive, [
        ['C+'],
        ['E+', 'C+'],
        ['E-'],
        ['O+'],
      ]);
      expect(r.outcome, 'C+'); // C+ 2, E 는 1-1=0, O+ 1
      expect(r.tally, {'C+': 2, 'E+': 1, 'E-': 1, 'O+': 1});
      expect(r.answers, 4);
    });

    test('dominant: 동률이면 먼저 드러난 극, 반대 극이 우세하면 낮은 극도 유형이 된다', () {
      expect(
        PersonalityScorer.score(enneagram, [
          ['5'],
          ['8'],
          ['8'],
          ['5'],
        ]).outcome,
        '5',
      );
      expect(
        PersonalityScorer.score(bigfive, [
          ['E-'],
          ['E-'],
          ['O+'],
        ]).outcome,
        'E-',
      );
    });

    test('dominant: 답이 없으면 첫 극', () {
      expect(PersonalityScorer.score(enneagram, const []).outcome, '1');
    });

    test('code: 축마다 많은 극, 동률은 나중에 드러난 극, 드러나지 않은 축은 답 수 홀짝', () {
      final r = PersonalityScorer.score(type16, [
        ['E', 'S'],
        ['I', 'N'],
        ['I', 'T'],
      ]);
      // E1 I2 -> I, S1 N1 동률 -> 나중의 N, T1 -> T, J/P 없음 -> 답 3개(홀수) -> P
      expect(r.outcome, 'INTP');
      expect(
        PersonalityScorer.score(type16, [
          ['E'],
          ['E'],
        ]).outcome,
        'ESTJ',
      );
    });

    test('같은 답이면 항상 같은 유형 (난수 없음)', () {
      final votes = [
        ['I', 'N'],
        ['E', 'S'],
        ['I', 'T'],
        ['E', 'S'],
      ];
      final outcomes = {
        for (var i = 0; i < 50; i++)
          PersonalityScorer.score(type16, votes).outcome,
      };
      expect(outcomes, hasLength(1));
    });

    test('readAttempts: 여러 시행의 답을 모두 모아 읽는다. 콘텐츠에 없는 답은 빈 표', () {
      final catalog = testCatalog(
        channel: taggedChannel(),
        theories: const [enneagram],
      );
      AttemptRecord rec(int i, List<String> choices) => AttemptRecord(
        index: i,
        channelId: 'wuxia',
        answers: answersOf(choices),
        archetype: 0,
        at: DateTime.utc(2026),
      );
      final r = PersonalityScorer.readAttempts(catalog, enneagram, [
        rec(1, ['c2', 'c2']),
        rec(2, ['c1', 'c3', 'c2', 'c9']),
      ]);
      expect(r.tally, {'5': 3, '8': 1, '1': 1});
      expect(r.outcome, '5');
      expect(r.answers, 6);
    });
  });

  group('TheoryPicker', () {
    test('직전 이론은 피하고, 이론이 하나뿐이면 그것을 쓴다', () {
      final random = Random(5);
      for (var i = 0; i < 200; i++) {
        expect(
          TheoryPicker.pick(
            const [bigfive, type16, enneagram],
            random,
            avoid: 'type16',
          )!.id,
          isNot('type16'),
        );
      }
      expect(
        TheoryPicker.pick(const [bigfive], random, avoid: 'bigfive')!.id,
        'bigfive',
      );
      expect(TheoryPicker.pick(const [], random), isNull);
    });

    test('3개 이론을 고르게 쓴다 (3,000회 중 이론별 비율 33%±3%p)', () {
      final random = Random(9);
      final counts = <String, int>{};
      for (var i = 0; i < 3000; i++) {
        final id = TheoryPicker.pick(const [
          bigfive,
          type16,
          enneagram,
        ], random)!.id;
        counts[id] = (counts[id] ?? 0) + 1;
      }
      for (final c in counts.values) {
        expect(c / 3000, closeTo(1 / 3, 0.03));
      }
    });
  });

  group('PlanAttemptUseCase + 성격 이론', () {
    final channel = taggedChannel();
    final catalog = testCatalog(
      channel: channel,
      theories: const [bigfive, type16, enneagram],
    );

    test('연속 200회: 시행마다 이론이 바뀌고, 결과 유형은 이번 답 4개로 계산되며 기록에 이론이 남는다', () async {
      final repo = InMemoryAccumulationRepository();
      final useCase = PlanAttemptUseCase(
        repo,
        Random(2026),
        () => DateTime.utc(2026),
      );
      final random = Random(1);
      String? previous;
      for (var i = 0; i < 200; i++) {
        final answers = answersOf([
          for (var q = 0; q < 4; q++) 'c${random.nextInt(3) + 1}',
        ]);
        final plan = (await useCase(
          catalog: catalog,
          channel: channel,
          answers: answers,
        )).dataOrNull!;
        final theory = catalog.theoryById(plan.attempt.theoryId)!;
        expect(plan.attempt.theoryId, isNot(previous));
        expect(
          plan.reading,
          PersonalityScorer.readAttempts(catalog, theory, [plan.attempt]),
        );
        expect(plan.reading!.answers, 4);
        expect(repo.state.attempts.last.theoryId, theory.id);
        previous = theory.id;
      }
    });

    test('발현: 이번 시행과 다른 이론으로 지금까지의 모든 답을 읽는다', () async {
      final repo = InMemoryAccumulationRepository(
        AccumulationState(
          attempts: [
            for (var i = 1; i <= 5; i++)
              AttemptRecord(
                index: i,
                channelId: 'wuxia',
                answers: answersOf(['c2', 'c2', 'c1', 'c3']),
                archetype: 0,
                at: DateTime.utc(2026),
                theoryId: 'bigfive',
              ),
          ],
          gaugePermille: 1000,
        ),
      );
      final plan =
          (await PlanAttemptUseCase(repo, Random(3), () => DateTime.utc(2026))(
            catalog: catalog,
            channel: channel,
            answers: answersOf(['c2', 'c2', 'c2', 'c2']),
          )).dataOrNull!;
      final m = plan.manifestation!;
      expect(m.theoryId, isNot(plan.attempt.theoryId));
      expect(repo.state.manifestations.single.theoryId, m.theoryId);
      expect(plan.deepReading!.theoryId, m.theoryId);
      expect(plan.deepReading!.answers, 24); // 지난 5회 x 4 + 이번 4
    });
  });

  group('ResultComposer + 성격 유형', () {
    final channel = taggedChannel();
    final catalog = testCatalog(
      channel: channel,
      theories: const [bigfive, enneagram],
    );
    final text = testText();
    final attempt = AttemptRecord(
      index: 7,
      channelId: 'wuxia',
      answers: answersOf(['c2', 'c1']),
      archetype: 1,
      at: DateTime.utc(2026),
      theoryId: 'enneagram',
    );
    const reading = TraitReading(
      theoryId: 'enneagram',
      outcome: '5',
      tally: {'5': 1, '8': 1},
      answers: 2,
    );
    const deep = TraitReading(
      theoryId: 'bigfive',
      outcome: 'E-',
      tally: {'C+': 3, 'E-': 9},
      answers: 12,
    );
    AttemptPlan planWith(ManifestationForm? form) => AttemptPlan(
      channelId: 'wuxia',
      attempt: attempt,
      manifestation: form == null
          ? null
          : ManifestationRecord(
              attemptIndex: 7,
              form: form,
              materials: [ref(MaterialKind.attempt, 4, c: 'c2')],
              theoryId: 'bigfive',
            ),
      reading: reading,
      deepReading: form == null ? null : deep,
    );
    const manifest = ManifestationText(
      lines: ['발현'],
      separateSpeaker: '목소리',
      separatePlace: '',
    );

    /// 화면에 보이는 모든 글자 (장소, 화자, 대사).
    Iterable<String> visible(EvaluationResult r) =>
        r.scenes.expand((x) => [x.place, x.speaker, ...x.lines]);

    test('첫 줄은 결과 유형 문장, 가운데는 성격 설명(모델이 없으면 설명/장점/약점), 끝 줄은 명언. 이론/유형 이름은 화면에 없다', () {
      final r = ResultComposer.compose(
        channel: channel,
        plan: planWith(null),
        text: text,
      );
      expect(r.scenes.single.lines, [
        'wuxia-reveal wuxia-title1',
        'theory.enneagram.5.desc',
        'theory.enneagram.5.strength',
        'theory.enneagram.5.weakness',
        'wuxia-a1-s2', // 시행 7회차 -> 명언 2번
      ]);
      expect(visible(r).where((t) => t.contains('.name') || t.contains('.label')), isEmpty);
      expect(r.reading, reading);
      expect(r.deepReading, isNull);
    });

    test('발현이 있으면 누적 유형을 결과에 남기되 화면에는 이론/유형 이름을 내지 않는다', () {
      for (final form in ManifestationForm.values) {
        final r = ResultComposer.compose(
          channel: channel,
          plan: planWith(form),
          text: text,
          manifest: manifest,
        );
        expect(r.deepReading, deep);
        expect(visible(r).where((t) => t.contains('.name') || t.contains('.label')), isEmpty);
      }
    });

    test('명언은 시행 순번에 따라 결과 유형의 2개 중 번갈아 나온다', () {
      String last(int index) => ResultComposer.baseScene(
        channel,
        3,
        text,
        lines: const ['x'],
        sayingIndex: index,
      ).lines.last;
      expect([last(1), last(2), last(3), last(4)], ['wuxia-a3-s2', 'wuxia-a3-s1', 'wuxia-a3-s2', 'wuxia-a3-s1']);
    });

    test('plainLabel: 유형 번호/코드를 떼어 프롬프트에 이론이 드러나지 않게 한다', () {
      expect(ResultComposer.plainLabel('5번 · 알아 두는 사람'), '알아 두는 사람');
      expect(ResultComposer.plainLabel('ISTJ · 묵묵한 관리자'), '묵묵한 관리자');
      expect(ResultComposer.plainLabel('내향(I)'), '내향');
      expect(ResultComposer.plainLabel('Introverted (I)'), 'Introverted');
      expect(ResultComposer.plainLabel('성실성 높음'), '성실성 높음');
    });

    test('대사 요청: 답마다 드러난 성향, 유형 설명, 누적 성향 표(많은 순), 기록의 성향', () {
      final plan = planWith(ManifestationForm.separate);
      final base = ResultComposer.baseRequest(
        channel,
        plan,
        text,
        catalog: catalog,
      );
      expect(base.answers.map((a) => a.$3), [
        'theory.enneagram.5.label',
        'theory.enneagram.8.label',
      ]);
      expect(base.profile!.description, 'theory.enneagram.5.desc');
      final m = ResultComposer.manifestationRequest(
        channel,
        plan,
        text,
        catalog: catalog,
      );
      expect(m.tally, [
        ('theory.bigfive.E-.label', 9),
        ('theory.bigfive.C+.label', 3),
      ]);
      expect(m.totalAnswers, 12);
      expect(m.materials.single.trait, 'theory.bigfive.E-.label');
      expect(m.today, ['wuxia-q1-c2', 'wuxia-q2-c1']);
    });
  });

  group('ResultComposer.supportingFirst', () {
    final catalog = testCatalog(channel: taggedChannel(), theories: const [enneagram, type16]);
    final mats = [
      ref(MaterialKind.attempt, 1, c: 'c1'), // 에니어그램 8, 16유형 E S
      ref(MaterialKind.attempt, 2, c: 'c2'), // 5, I N
      ref(MaterialKind.manifestation, 3, c: 'c3'), // 1, I T
      ref(MaterialKind.attempt, 4, c: 'c2'), // 5, I N
    ];

    test('dominant: 누적 유형과 같은 극의 기록이 먼저, 나머지는 원래 순서', () {
      const deep = TraitReading(theoryId: 'enneagram', outcome: '5', tally: {}, answers: 0);
      expect(
        ResultComposer.supportingFirst(mats, catalog, deep).map((m) => m.sourceIndex),
        [2, 4, 1, 3],
      );
    });

    test('code: 유형 글자와 겹치는 극이 많은 순', () {
      const deep = TraitReading(theoryId: 'type16', outcome: 'INTJ', tally: {}, answers: 0);
      // c1: E S -> 0, c2: I N -> 2, c3: I T -> 2
      expect(
        ResultComposer.supportingFirst(mats, catalog, deep).map((m) => m.sourceIndex),
        [2, 3, 4, 1],
      );
    });

    test('누적 유형이나 이론이 없으면 그대로', () {
      expect(ResultComposer.supportingFirst(mats, catalog, null), mats);
    });
  });

  test('템플릿 발현 대사의 마지막 줄은 누적 유형 설명', () {
    final t = {
      'mixed.intro': ['인트로'],
      'separate.intro': ['인트로'],
      'recall.attempt': ['{ago}번 전 {choice}'],
      'recall.manifest': ['{ago}번 전에도 {choice}'],
      'close': ['맺음'],
      'separate.speaker': '목소리',
      'separate.place': '어딘가',
    };
    const material = ResolvedMaterial(
      kind: MaterialKind.attempt,
      ago: 2,
      channelName: '무협',
      choiceText: '검',
    );
    const profile = TypeProfile(
      theoryName: '4기질',
      label: '점액질',
      description: '서두르지 않는 사람이다',
      strength: 's',
      weakness: 'w',
    );
    final lines = TemplateNarrationEngine.compose(
      t,
      ManifestationForm.separate,
      [material],
      Random(1),
      profile: profile,
    ).lines;
    expect(lines, ['인트로', '2번 전 검', '서두르지 않는 사람이다']);
    expect(
      TemplateNarrationEngine.compose(t, ManifestationForm.separate, [
        material,
      ], Random(1)).lines.last,
      '맺음',
    );
  });

  test('AccumulationMapper: 이론 id 왕복, 이론 도입 전 기록은 null', () {
    final state = AccumulationState(
      attempts: [
        AttemptRecord(
          index: 1,
          channelId: 'wuxia',
          answers: answersOf(['c1']),
          archetype: 0,
          at: DateTime.utc(2026),
          theoryId: 'type16',
        ),
        attempt(2),
      ],
      manifestations: [
        ManifestationRecord(
          attemptIndex: 2,
          form: ManifestationForm.mixed,
          materials: [ref(MaterialKind.attempt, 1)],
          theoryId: 'bigfive',
        ),
      ],
    );
    final back = AccumulationMapper.fromJson(AccumulationMapper.toJson(state));
    expect(back, state);
    expect(back.attempts.last.theoryId, isNull);
  });
}
