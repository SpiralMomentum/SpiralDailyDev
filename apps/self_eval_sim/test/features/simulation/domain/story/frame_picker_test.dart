import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/catalog.dart';
import 'package:self_eval_sim/features/simulation/domain/story/frame_picker.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_ledger.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_record.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_world.dart';

import '../../../../support/story_fixtures.dart';

const _theory = Theory(
  id: 't',
  mode: TheoryMode.dominant,
  axes: [
    ['A'],
    ['B'],
  ],
);

StoryFrame _frame(
  String id, {
  List<String> axes = const ['who'],
  Set<String> requires = const {},
}) => StoryFrame(
  id: id,
  axes: axes,
  requiresStatus: requires,
  choices: const [
    FrameChoice(
      id: 'c1',
      traits: {
        't': ['A'],
      },
    ),
    FrameChoice(
      id: 'c2',
      traits: {
        't': ['B'],
      },
    ),
  ],
);

StoryWorld _world(
  List<StoryFrame> frames, {
  Map<String, List<String>> variants = const {
    'who': ['x', 'y', 'z'],
  },
  List<StoryEvent> events = const [],
}) => StoryWorld(
  id: 'w',
  characters: const [StoryCharacter(id: 'a', theoryId: 't', unlockAt: 0)],
  theories: const [_theory],
  frames: frames,
  variants: variants,
  events: events,
  links: const [],
);

StoryMeeting _meeting(
  int n,
  String who,
  List<PickedFrame> picked, {
  String choice = 'c1',
  String? eventId,
}) => StoryMeeting(
  number: n,
  characterId: who,
  relationship: Relationship.friend,
  answers: [
    for (final p in picked)
      StoryAnswer(frameId: p.frame.id, variant: p.variant, choiceId: choice),
  ],
  outcome: 'o',
  at: DateTime(2026, 1, n),
  eventId: eventId,
);

void main() {
  final innkeeper = miniWorld.characters.first;

  test('인물 이론 태그가 있는 틀만, 서로 다른 틀로 (count 보다 적으면 있는 만큼)', () {
    final ledger = StoryLedger.of(miniWorld, const []);
    final picked = FramePicker.pick(miniWorld, ledger, innkeeper, Random(1));
    expect(picked, hasLength(2)); // bigfive 틀은 f_help, f_trade 둘뿐
    expect(picked.map((p) => p.frame.id).toSet(), {'f_help', 'f_trade'});
    final smith = miniWorld.characters[1];
    final p2 = FramePicker.pick(miniWorld, ledger, smith, Random(1), count: 4);
    expect(p2.map((p) => p.frame.id).toSet(), {'f_lost', 'f_feast'});
  });

  test('주도 방식도 같은 순위 안에서는 모든 선택지가 이론을 태그한 틀을 먼저 고른다', () {
    // partial: c2 는 이 이론 태그가 없다 (고르면 판단 근거가 없다).
    const partial = StoryFrame(
      id: 'partial',
      axes: ['who'],
      choices: [
        FrameChoice(
          id: 'c1',
          traits: {
            't': ['A'],
          },
        ),
        FrameChoice(id: 'c2', traits: {}),
      ],
    );
    final world = _world([
      for (var i = 0; i < 3; i++)
        StoryFrame(id: 'p$i', axes: partial.axes, choices: partial.choices),
      _frame('full0'),
      _frame('full1'),
    ]);
    for (var seed = 0; seed < 30; seed++) {
      final ids = FramePicker.pick(
        world,
        StoryLedger.of(world, const []),
        world.characters.first,
        Random(seed),
        count: 2,
      ).map((p) => p.frame.id).toSet();
      expect(ids, {'full0', 'full1'}, reason: '$seed');
    }
  });

  test('인물 장소가 있으면 where 는 그 장소만 하나, 같은 who 는 두 질문까지', () {
    final world = StoryWorld(
      id: 'w',
      characters: const [
        StoryCharacter(
          id: 'a',
          theoryId: 't',
          unlockAt: 0,
          places: ['p1', 'p2'],
        ),
      ],
      theories: const [_theory],
      frames: [
        for (var i = 0; i < 4; i++)
          _frame(
            'f$i',
            axes: i.isEven ? const ['who', 'where'] : const ['who'],
          ),
      ],
      variants: const {
        'who': ['x', 'y', 'z'],
        'where': ['p1', 'p2', 'p3', 'p4'],
      },
      events: const [],
      links: const [],
    );
    for (var seed = 0; seed < 30; seed++) {
      final picked = FramePicker.pick(
        world,
        StoryLedger.of(world, const []),
        world.characters.first,
        Random(seed),
      );
      expect(picked, hasLength(4));
      final whos = [for (final p in picked) ?p.variant['who']];
      expect(whos.toSet(), hasLength(2), reason: '$seed');
      for (final w in whos.toSet()) {
        expect(whos.where((x) => x == w), hasLength(2), reason: '$seed');
      }
      final places = {for (final p in picked) ?p.variant['where']};
      expect(places, hasLength(1), reason: '$seed');
      expect(['p1', 'p2'], contains(places.single), reason: '$seed');
    }
  });

  test('안 쓴 틀이 남아 있으면 쓴 틀은 나오지 않는다', () {
    final world = _world([for (var i = 0; i < 6; i++) _frame('f$i')]);
    for (var seed = 0; seed < 20; seed++) {
      final first = FramePicker.pick(
        world,
        StoryLedger.of(world, const []),
        world.characters.first,
        Random(seed),
        count: 3,
      );
      final ledger = StoryLedger.of(world, [_meeting(1, 'a', first)]);
      final second = FramePicker.pick(
        world,
        ledger,
        world.characters.first,
        Random(seed + 100),
        count: 3,
      );
      final used = first.map((p) => p.frame.id).toSet();
      expect(second.map((p) => p.frame.id).toSet().intersection(used), isEmpty);
    }
  });

  test('같은 인물에게 같은 (틀, 변주) 조합은 조합이 남은 동안 다시 나오지 않는다', () {
    // 틀 3 x (who 2 x where 2) = 조합 12. 12개를 다 쓸 때까지 중복 0.
    final world = _world(
      [
        for (var i = 0; i < 3; i++) _frame('f$i', axes: ['who', 'where']),
      ],
      variants: {
        'who': ['x', 'y'],
        'where': ['p', 'q'],
      },
    );
    for (var seed = 1; seed <= 10; seed++) {
      final random = Random(seed);
      final meetings = <StoryMeeting>[];
      final keys = <String>[];
      for (var n = 1; n <= 12; n++) {
        final picked = FramePicker.pick(
          world,
          StoryLedger.of(world, meetings),
          world.characters.first,
          random,
          count: 1,
          gap: 0,
        );
        final m = _meeting(n, 'a', picked);
        keys.add(m.answers.first.comboKey);
        meetings.add(m);
      }
      expect(keys.toSet(), hasLength(12), reason: 'seed $seed');
    }
  });

  test('조합이 남은 틀이 있으면 조합을 다 쓴 틀은 뒤로 간다', () {
    final world = _world(
      [
        _frame('full'),
        _frame('open', axes: ['who', 'where']),
      ],
      variants: {
        'who': ['x'],
        'where': ['p', 'q'],
      },
    );
    // full 은 where 축이 없어 조합 1개, 이미 씀. open 은 조합 2개 중 1개 씀.
    final past = _meeting(1, 'a', const [], eventId: null);
    final meeting = StoryMeeting(
      number: 1,
      characterId: 'a',
      relationship: Relationship.friend,
      answers: const [
        StoryAnswer(frameId: 'full', variant: {'who': 'x'}, choiceId: 'c1'),
        StoryAnswer(
          frameId: 'open',
          variant: {'who': 'x', 'where': 'p'},
          choiceId: 'c1',
        ),
      ],
      outcome: 'o',
      at: DateTime(2026),
    );
    expect(past.number, 1);
    final ledger = StoryLedger.of(world, [meeting]);
    for (var seed = 0; seed < 10; seed++) {
      final picked = FramePicker.pick(
        world,
        ledger,
        world.characters.first,
        Random(seed),
        count: 1,
        gap: 0,
      );
      expect(picked.single.frame.id, 'open');
      expect(picked.single.variant['where'], 'q');
    }
  });

  test('조합을 다 쓴 뒤에는 가장 오래전에 쓴 조합으로 돌아가고 최근 선택지를 붙인다', () {
    final world = _world(
      [_frame('f0')],
      variants: {
        'who': ['x', 'y', 'z'],
      },
    );
    // 사용 순서 y, x, z (x 는 두 번째). 선택지는 c1, c2, c1.
    StoryMeeting m(int n, String who, String choice) => StoryMeeting(
      number: n,
      characterId: 'a',
      relationship: Relationship.friend,
      answers: [
        StoryAnswer(frameId: 'f0', variant: {'who': who}, choiceId: choice),
      ],
      outcome: 'o',
      at: DateTime(2026, 1, n),
    );
    final ledger = StoryLedger.of(world, [
      m(1, 'y', 'c1'),
      m(2, 'x', 'c2'),
      m(3, 'z', 'c1'),
    ]);
    final picked = FramePicker.pick(
      world,
      ledger,
      world.characters.first,
      Random(3),
      count: 1,
    ).single;
    expect(picked.variant, {'who': 'y'});
    expect(picked.recallChoiceId, 'c1');

    // y 를 다시 쓴 뒤에는 x 가 가장 오래됐고, 지난 선택지는 가장 최근 것이다.
    final ledger2 = StoryLedger.of(world, [
      m(1, 'y', 'c1'),
      m(2, 'x', 'c2'),
      m(3, 'z', 'c1'),
      m(4, 'y', 'c2'),
    ]);
    final next = FramePicker.pick(
      world,
      ledger2,
      world.characters.first,
      Random(3),
      count: 1,
    ).single;
    expect(next.variant, {'who': 'x'});
    expect(next.recallChoiceId, 'c2');
  });

  test('변주 축이 world.variants 에 없는 틀은 건너뛴다', () {
    final world = _world([
      _frame('ok'),
      _frame('broken', axes: ['nowhere']),
    ]);
    final picked = FramePicker.pick(
      world,
      StoryLedger.of(world, const []),
      world.characters.first,
      Random(1),
    );
    expect(picked.map((p) => p.frame.id), ['ok']);
  });

  test('상태 조건: forbidsStatus 상태가 있으면 그 틀은 제외', () {
    const grant = StoryEvent(
      id: 'e',
      characterId: 'a',
      grantsStatus: 'martial',
    );
    final world = _world(
      [
        _frame('plain'),
        const StoryFrame(
          id: 'peace',
          axes: ['who'],
          forbidsStatus: {'martial'},
          choices: [
            FrameChoice(
              id: 'c1',
              traits: {
                't': ['A'],
              },
            ),
          ],
        ),
      ],
      events: [grant],
    );
    final c = world.characters.first;
    final before = FramePicker.pick(
      world,
      StoryLedger.of(world, const []),
      c,
      Random(1),
    );
    expect(before.map((p) => p.frame.id).toSet(), {'plain', 'peace'});
    final after = FramePicker.pick(
      world,
      StoryLedger.of(world, [_meeting(1, 'a', const [], eventId: 'e')]),
      c,
      Random(1),
    );
    expect(after.map((p) => p.frame.id), ['plain']);
  });

  test('다시 나온 틀에는 지난 선택지가 recallChoiceId 로 붙는다', () {
    final world = _world([_frame('f0'), _frame('f1')]);
    final c = world.characters.first;
    final first = FramePicker.pick(
      world,
      StoryLedger.of(world, const []),
      c,
      Random(1),
      count: 2,
    );
    expect(first.every((p) => p.recallChoiceId == null), isTrue);
    final ledger = StoryLedger.of(world, [
      _meeting(1, 'a', first, choice: 'c2'),
    ]);
    final second = FramePicker.pick(world, ledger, c, Random(2), count: 2);
    expect(second.every((p) => p.recallChoiceId == 'c2'), isTrue);
  });

  test('최근 2만남에 다른 인물이 쓴 틀은 뒤로 밀린다', () {
    final world = _world([for (var i = 0; i < 4; i++) _frame('f$i')]);
    final other = _meeting(1, 'b', [
      PickedFrame(frame: world.frames[0], variant: const {'who': 'x'}),
      PickedFrame(frame: world.frames[1], variant: const {'who': 'x'}),
    ]);
    final ledger = StoryLedger.of(world, [other]);
    for (var seed = 0; seed < 20; seed++) {
      final picked = FramePicker.pick(
        world,
        ledger,
        world.characters.first,
        Random(seed),
        count: 2,
      );
      expect(picked.map((p) => p.frame.id).toSet(), {'f2', 'f3'});
    }
    // 틀이 모자라면 미뤄진 틀로 채운다.
    final all = FramePicker.pick(
      world,
      ledger,
      world.characters.first,
      Random(1),
      count: 4,
    );
    expect(all.map((p) => p.frame.id).toSet(), hasLength(4));
    expect(all.take(2).map((p) => p.frame.id).toSet(), {'f2', 'f3'});
  });

  test('조합을 다 쓰면 가장 오래된 조합을 연결 문장과 함께 다시 쓴다', () {
    final world = _world(
      [for (var i = 0; i < 4; i++) _frame('f$i')],
      variants: {
        'who': ['x'],
      },
    );
    final c = world.characters.first;
    final first = FramePicker.pick(
      world,
      StoryLedger.of(world, const []),
      c,
      Random(1),
    );
    expect(first, hasLength(4));
    final ledger = StoryLedger.of(world, [_meeting(1, 'a', first)]);
    final second = FramePicker.pick(world, ledger, c, Random(2));
    expect(second, hasLength(4));
    expect(second.every((p) => p.recallChoiceId == 'c1'), isTrue);
    expect(second.every((p) => p.variant['who'] == 'x'), isTrue);
  });

  test('상태 조건: martial 이 없으면 requiresStatus martial 틀은 제외', () {
    const grant = StoryEvent(
      id: 'e',
      characterId: 'a',
      grantsStatus: 'martial',
    );
    final world = _world(
      [
        _frame('plain'),
        _frame('fight', requires: {'martial'}),
      ],
      events: [grant],
    );
    final c = world.characters.first;
    final without = FramePicker.pick(
      world,
      StoryLedger.of(world, const []),
      c,
      Random(1),
    );
    expect(without.map((p) => p.frame.id), ['plain']);
    final withStatus = FramePicker.pick(
      world,
      StoryLedger.of(world, [_meeting(1, 'a', const [], eventId: 'e')]),
      c,
      Random(1),
    );
    expect(withStatus.map((p) => p.frame.id).toSet(), {'plain', 'fight'});
  });

  group('인물 이론이 재는 축', () {
    // 기질(code): bf 태그 중 E, N 만 잰다.
    const temperament = Theory(
      id: 'temper',
      mode: TheoryMode.code,
      axes: [
        ['E+', 'E-'],
        ['N+', 'N-'],
      ],
      measures: 'bf',
    );
    const bf = Theory(
      id: 'bf',
      mode: TheoryMode.dominant,
      axes: [
        ['E+', 'E-'],
        ['A+', 'A-'],
        ['N+', 'N-'],
      ],
    );
    StoryFrame tagged(String id, String plus, String minus) => StoryFrame(
      id: id,
      axes: const ['who'],
      choices: [
        FrameChoice(
          id: 'c1',
          traits: {
            'bf': [plus],
          },
        ),
        FrameChoice(
          id: 'c2',
          traits: {
            'bf': [minus],
          },
        ),
      ],
    );
    StoryWorld world(List<StoryFrame> frames) => StoryWorld(
      id: 'w',
      characters: const [
        StoryCharacter(id: 'doc', theoryId: 'temper', unlockAt: 0),
      ],
      theories: const [bf, temperament],
      frames: frames,
      variants: const {
        'who': ['x', 'y', 'z'],
      },
      events: const [],
      links: const [],
    );

    test('재는 극(E, N)을 태그한 선택지가 없는 틀은 쓰지 않는다', () {
      final w = world([
        for (var i = 0; i < 6; i++) tagged('a$i', 'A+', 'A-'),
        tagged('e', 'E+', 'E-'),
        tagged('n', 'N+', 'N-'),
      ]);
      for (var seed = 0; seed < 20; seed++) {
        final picked = FramePicker.pick(
          w,
          StoryLedger.of(w, const []),
          w.characters.first,
          Random(seed),
        );
        expect(picked.map((p) => p.frame.id).toSet(), {'e', 'n'});
      }
    });

    test('코드 방식은 틀이 넉넉하면 한 만남에서 모든 축을 한 번 이상 묻는다', () {
      final w = world([
        for (var i = 0; i < 8; i++) tagged('e$i', 'E+', 'E-'),
        tagged('n', 'N+', 'N-'),
      ]);
      for (var seed = 0; seed < 30; seed++) {
        final picked = FramePicker.pick(
          w,
          StoryLedger.of(w, const []),
          w.characters.first,
          Random(seed),
          count: 2,
        );
        expect(picked, hasLength(2));
        expect(picked.map((p) => p.frame.id), contains('n'), reason: '$seed');
      }
    });

    test('축을 덮을 때 모든 선택지가 그 축을 태그한 틀을 일부만 태그한 틀보다 먼저 고른다', () {
      // np: N 은 c1 에만, c2 는 재지 않는 A 태그. nf: 두 선택지 모두 N.
      final w = world([
        for (var i = 0; i < 4; i++) tagged('e$i', 'E+', 'E-'),
        tagged('np', 'N+', 'A+'),
        tagged('nf', 'N+', 'N-'),
      ]);
      for (var seed = 0; seed < 30; seed++) {
        final ids = FramePicker.pick(
          w,
          StoryLedger.of(w, const []),
          w.characters.first,
          Random(seed),
          count: 2,
        ).map((p) => p.frame.id);
        expect(ids, contains('nf'), reason: '$seed');
        expect(ids, isNot(contains('np')), reason: '$seed');
      }
    });

    test('축을 덮는 틀이 쓴 틀뿐이면 안 쓴 틀을 먼저 낸다', () {
      final w = world([
        for (var i = 0; i < 3; i++) tagged('e$i', 'E+', 'E-'),
        tagged('n', 'N+', 'N-'),
      ]);
      final ledger = StoryLedger.of(w, [
        _meeting(1, 'doc', [
          PickedFrame(frame: w.frames.last, variant: const {'who': 'x'}),
        ]),
      ]);
      final picked = FramePicker.pick(
        w,
        ledger,
        w.characters.first,
        Random(1),
        count: 3,
        gap: 0,
      );
      expect(picked.map((p) => p.frame.id).toSet(), {'e0', 'e1', 'e2'});
    });
  });
}
