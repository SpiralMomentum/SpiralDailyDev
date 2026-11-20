import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/catalog.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_judge.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_world.dart';

WeightedVote v(String pole, {double w = 1}) => (poles: [pole], weight: w);
List<WeightedVote> many(String pole, int n, {double w = 1}) => [
  for (var i = 0; i < n; i++) v(pole, w: w),
];

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
  measures: 'bigfive',
  axes: [
    ['E', 'I'],
    ['S', 'N'],
    ['T', 'F'],
    ['J', 'P'],
  ],
  poleAlias: {'E+': 'E', 'O+': 'N'},
);

const sanguine = Theory(
  id: 'temperament',
  mode: TheoryMode.code,
  axes: [
    ['E+', 'E-'],
    ['N+', 'N-'],
  ],
  outcomeAlias: {
    'E+N-': 'sanguine',
    'E-N+': 'melancholic',
    'E+N+': 'choleric',
    'E-N-': 'phlegmatic',
  },
);

void main() {
  test('첫 판단은 first 이고 누적 최다 극', () {
    final j = StoryJudge.judge(
      bigfive,
      history: const [],
      current: [...many('C+', 3), v('E+')],
    );
    expect(j.outcome, 'C+');
    expect(j.tone, JudgmentTone.first);
  });

  test('같은 쪽 답이면 confirmed', () {
    final j = StoryJudge.judge(
      bigfive,
      previous: 'C+',
      history: many('C+', 3),
      current: [...many('C+', 2), ...many('O+', 2)],
    );
    expect(j.outcome, 'C+');
    expect(j.tone, JudgmentTone.confirmed);
  });

  test('근거가 문턱만큼 쌓이지 않으면 판단을 유지하고 surprised', () {
    final j = StoryJudge.judge(
      bigfive,
      previous: 'C+',
      history: many('C+', 4),
      current: many('C-', 4),
    );
    expect(j.outcome, 'C+');
    expect(j.tone, JudgmentTone.surprised);
  });

  test('근거가 문턱 이상 쌓이면 판단이 바뀐다', () {
    final j = StoryJudge.judge(
      bigfive,
      previous: 'C+',
      history: many('C+', 1),
      current: many('C-', 4),
    );
    expect(j.outcome, 'C-');
    expect(j.tone, JudgmentTone.confirmed);
  });

  test('소문 가중치 0.5 가 반영된다', () {
    final j = StoryJudge.judge(
      bigfive,
      history: many('O+', 3, w: StoryRules.rumorWeight),
      current: [v('E+')],
    );
    expect(j.outcome, 'O+');
    expect(j.tally['O+'], 1.5);
  });

  test('16상은 빅파이브 태그를 별칭으로 읽어 네 글자 유형', () {
    final poles = StoryJudge.poles(
      type16,
      const FrameChoice(
        id: 'a',
        traits: {
          'bigfive': ['E+', 'O+'],
        },
      ),
    );
    expect(poles, ['E', 'N']);
    final r = StoryJudge.score(type16, [v('E'), v('N'), v('F'), v('J')]);
    expect(r.outcome, 'ENFJ');
  });

  test('4체질은 E x N 코드를 기질 이름으로', () {
    final r = StoryJudge.score(sanguine, [v('E+'), v('N-')]);
    expect(r.outcome, 'sanguine');
    final j = StoryJudge.judge(
      sanguine,
      previous: 'sanguine',
      history: const [],
      current: [v('E-'), v('N+')],
    );
    expect(j.outcome, 'sanguine');
    expect(j.tone, JudgmentTone.surprised);
  });

  group('코드 방식 tone 은 이번 답이 건드린 축만 본다', () {
    test('이번 답이 닿지 않은 축은 의외로 치지 않는다', () {
      final j = StoryJudge.judge(
        type16,
        previous: 'ENFJ',
        history: [...many('E', 3), ...many('N', 3), ...many('F', 3), ...many('J', 3)],
        current: [v('E'), v('N')],
      );
      expect(j.outcome, 'ENFJ');
      expect(j.tone, JudgmentTone.confirmed);
    });

    test('건드린 축 하나라도 판단과 다르면 surprised', () {
      final j = StoryJudge.judge(
        type16,
        previous: 'ENFJ',
        history: [...many('E', 4), ...many('N', 3), ...many('F', 3), ...many('J', 3)],
        current: [v('I'), v('N')],
      );
      expect(j.outcome, 'ENFJ');
      expect(j.tone, JudgmentTone.surprised);
    });

    test('별칭 결과도 같은 규칙 (4체질)', () {
      final j = StoryJudge.judge(
        sanguine,
        previous: 'sanguine',
        history: [...many('E+', 3), ...many('N-', 3)],
        current: [v('E+')],
      );
      expect(j.outcome, 'sanguine');
      expect(j.tone, JudgmentTone.confirmed);
    });
  });

  group('코드 방식 동점/미등장 축', () {
    test('이전 판단이 있으면 그 글자를 유지한다 (문턱과 무관)', () {
      final j = StoryJudge.judge(
        type16,
        previous: 'INFP',
        history: const [],
        current: [v('I'), v('E')],
        switchMargin: 0,
      );
      expect(j.outcome, 'INFP');
    });

    test('이전 판단이 없으면 나중에 드러난 극, 표가 없으면 첫 극', () {
      final j = StoryJudge.judge(
        type16,
        history: const [],
        current: [v('I'), v('E'), v('F')],
      );
      expect(j.outcome, 'ESFJ');
    });

    test('동점이 아닌 축은 이전 판단과 상관없이 표를 따른다 (문턱 0)', () {
      final j = StoryJudge.judge(
        type16,
        previous: 'INFP',
        history: const [],
        current: [v('E'), v('S')],
        switchMargin: 0,
      );
      expect(j.outcome, 'ESFP');
    });
  });

  group('주도 방식 tone 은 이번 답이 판단과 반대쪽일 때만 surprised', () {
    const conflict = Theory(
      id: 'conflict',
      mode: TheoryMode.dominant,
      axes: [
        ['compete'],
        ['avoid'],
        ['compromise'],
      ],
    );

    test('양극 축: 판단한 축을 건드리지 않고 다른 축만 많으면 neutral (재회 중립)', () {
      final j = StoryJudge.judge(
        bigfive,
        previous: 'C+',
        history: many('C+', 4),
        current: many('O+', 3),
      );
      expect(j.outcome, 'C+');
      expect(j.tone, JudgmentTone.neutral);
    });

    test('양극 축: 판단한 축에서 반대 극이 더 많으면 surprised', () {
      final j = StoryJudge.judge(
        bigfive,
        previous: 'C+',
        history: many('C+', 6),
        current: [v('C-'), v('O+')],
      );
      expect(j.outcome, 'C+');
      expect(j.tone, JudgmentTone.surprised);
    });

    test('단극 범주: 판단한 범주가 이번에 한 번이라도 나오면 confirmed', () {
      final j = StoryJudge.judge(
        conflict,
        previous: 'compete',
        history: many('compete', 5),
        current: [v('avoid'), v('avoid'), v('compete')],
      );
      expect(j.tone, JudgmentTone.confirmed);
    });

    test('단극 범주: 판단한 범주가 이번에 없고 다른 범주만 나오면 surprised', () {
      final j = StoryJudge.judge(
        conflict,
        previous: 'compete',
        history: many('compete', 5),
        current: [v('avoid'), v('compromise')],
      );
      expect(j.outcome, 'compete');
      expect(j.tone, JudgmentTone.surprised);
    });

    test('이번 답에 이 이론의 표가 없으면 neutral (재회 중립)', () {
      final j = StoryJudge.judge(
        conflict,
        previous: 'compete',
        history: many('compete', 5),
        current: const [(poles: <String>[], weight: 1.0)],
      );
      expect(j.tone, JudgmentTone.neutral);
    });

    test('첫 만남은 표가 없어도 first', () {
      final j = StoryJudge.judge(
        conflict,
        history: const [],
        current: const [(poles: <String>[], weight: 1.0)],
      );
      expect(j.tone, JudgmentTone.first);
    });
  });

  group('재회 중립 (코드 방식)', () {
    test('이번 답이 어느 축에도 표를 안 냈으면 neutral', () {
      final j = StoryJudge.judge(
        type16,
        previous: 'ENFJ',
        history: [...many('E', 3), ...many('N', 3)],
        current: const [(poles: <String>[], weight: 1.0)],
      );
      expect(j.outcome, 'ENFJ');
      expect(j.tone, JudgmentTone.neutral);
    });
  });

  group('이전 판단이 이 이론의 결과가 아니면 없는 것으로 본다', () {
    test('주도 방식: 목록에 없는 이전 판단은 first, 결과는 이번 표대로', () {
      final j = StoryJudge.judge(
        bigfive,
        previous: 'compete',
        history: const [],
        current: many('O+', 2),
      );
      expect(j.outcome, 'O+');
      expect(j.tone, JudgmentTone.first);
    });

    test('코드 방식: 해석할 수 없는 이전 판단은 first', () {
      final j = StoryJudge.judge(
        type16,
        previous: 'XYZ',
        history: const [],
        current: [v('I'), v('S'), v('T'), v('P')],
      );
      expect(j.outcome, 'ISTP');
      expect(j.tone, JudgmentTone.first);
    });
  });

  test('poles 는 이론 축에 있는 극만 돌려준다 (다른 이론 태그를 빌려 읽을 때 남는 극 제외)', () {
    const temperament = Theory(
      id: 'temperament',
      mode: TheoryMode.code,
      measures: 'bigfive',
      axes: [
        ['E+', 'E-'],
        ['N+', 'N-'],
      ],
    );
    const choice = FrameChoice(
      id: 'a',
      traits: {
        'bigfive': ['E+', 'C-', 'N-'],
      },
    );
    expect(StoryJudge.poles(temperament, choice), ['E+', 'N-']);
    expect(
      StoryJudge.poles(
        type16,
        const FrameChoice(
          id: 'b',
          traits: {
            'bigfive': ['E+', 'N-'],
          },
        ),
      ),
      ['E'],
    );
  });
}
