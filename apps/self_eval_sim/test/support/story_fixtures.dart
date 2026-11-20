import 'package:self_eval_sim/features/simulation/domain/entities/catalog.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/text_book.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_judge.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_record.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_repository.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_world.dart';
import 'package:utils/utils.dart';

/// 이야기 모드 테스트가 함께 쓰는 작은 세계.
/// 인물 3, 틀 6(id 는 `f_` 로 시작), 변주 축 who/where 각 3, 사건 1, 연결 1.
/// 틀 f_help/f_trade 는 bigfive, f_lost/f_feast 는 holland, f_duel/f_secret 은 values 태그를 가진다.
const miniWorld = StoryWorld(
  id: 'mini',
  characters: [
    StoryCharacter(id: 'innkeeper', theoryId: 'bigfive', unlockAt: 0),
    StoryCharacter(id: 'smith', theoryId: 'holland', unlockAt: 2),
    StoryCharacter(
      id: 'hermit',
      theoryId: 'values',
      unlockAt: 4,
      requires: {'innkeeper': 3},
    ),
  ],
  theories: [
    Theory(
      id: 'bigfive',
      mode: TheoryMode.dominant,
      axes: [
        ['O+', 'O-'],
        ['C+', 'C-'],
        ['E+', 'E-'],
        ['A+', 'A-'],
        ['N+', 'N-'],
      ],
    ),
    Theory(
      id: 'holland',
      mode: TheoryMode.dominant,
      axes: [
        ['R'],
        ['I'],
        ['A'],
        ['S'],
        ['E'],
        ['C'],
      ],
    ),
    Theory(
      id: 'values',
      mode: TheoryMode.dominant,
      axes: [
        ['power'],
        ['care'],
        ['freedom'],
      ],
    ),
    Theory(
      id: 'type16',
      mode: TheoryMode.code,
      axes: [
        ['E', 'I'],
        ['S', 'N'],
        ['T', 'F'],
        ['J', 'P'],
      ],
      measures: 'bigfive',
      poleAlias: {
        'E+': 'E',
        'E-': 'I',
        'O+': 'N',
        'O-': 'S',
        'A+': 'F',
        'A-': 'T',
        'C+': 'J',
        'C-': 'P',
      },
    ),
  ],
  frames: [
    StoryFrame(
      id: 'f_help',
      axes: ['who', 'where'],
      choices: [
        FrameChoice(
          id: 'c1',
          traits: {
            'bigfive': ['O+'],
          },
        ),
        FrameChoice(
          id: 'c2',
          traits: {
            'bigfive': ['C+'],
          },
        ),
        FrameChoice(
          id: 'c3',
          traits: {
            'bigfive': ['E+'],
          },
        ),
      ],
    ),
    StoryFrame(
      id: 'f_trade',
      axes: ['who'],
      choices: [
        FrameChoice(
          id: 'c1',
          traits: {
            'bigfive': ['A+'],
          },
        ),
        FrameChoice(
          id: 'c2',
          traits: {
            'bigfive': ['N+'],
          },
        ),
        FrameChoice(
          id: 'c3',
          traits: {
            'bigfive': ['E-'],
          },
        ),
      ],
    ),
    StoryFrame(
      id: 'f_lost',
      axes: ['who', 'where'],
      choices: [
        FrameChoice(
          id: 'c1',
          traits: {
            'holland': ['R'],
          },
        ),
        FrameChoice(
          id: 'c2',
          traits: {
            'holland': ['I'],
          },
        ),
        FrameChoice(
          id: 'c3',
          traits: {
            'holland': ['A'],
          },
        ),
      ],
    ),
    StoryFrame(
      id: 'f_feast',
      axes: ['who'],
      choices: [
        FrameChoice(
          id: 'c1',
          traits: {
            'holland': ['S'],
          },
        ),
        FrameChoice(
          id: 'c2',
          traits: {
            'holland': ['E'],
          },
        ),
        FrameChoice(
          id: 'c3',
          traits: {
            'holland': ['C'],
          },
        ),
      ],
    ),
    StoryFrame(
      id: 'f_duel',
      axes: ['who', 'where'],
      choices: [
        FrameChoice(
          id: 'c1',
          traits: {
            'values': ['power'],
          },
        ),
        FrameChoice(
          id: 'c2',
          traits: {
            'values': ['care'],
          },
        ),
        FrameChoice(
          id: 'c3',
          traits: {
            'values': ['freedom'],
          },
        ),
      ],
    ),
    StoryFrame(
      id: 'f_secret',
      axes: ['who'],
      choices: [
        FrameChoice(
          id: 'c1',
          traits: {
            'values': ['power'],
          },
        ),
        FrameChoice(
          id: 'c2',
          traits: {
            'values': ['care'],
          },
        ),
        FrameChoice(
          id: 'c3',
          traits: {
            'values': ['freedom'],
          },
        ),
      ],
    ),
  ],
  variants: {
    'who': ['stranger', 'friend', 'elder'],
    'where': ['inn', 'market', 'road'],
  },
  events: [
    StoryEvent(
      id: 'old_friends',
      characterId: 'hermit',
      met: {'innkeeper': 3},
      reveals: [('innkeeper', 'hermit')],
    ),
  ],
  links: [('innkeeper', 'smith')],
);

/// 객잔 주인(bigfive)이 한 만남에 질문 4개를 받을 수 있게 bigfive 틀을 4개(f_b1..f_b4)로 바꾼 세계.
/// 선택지는 c1 = C+, c2 = C-, c3 = 이 이론에서 중립(태그 없음).
final quizWorld = StoryWorld(
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

/// [miniWorld] 를 world.json 형식으로 쓴 것.
const Map<String, dynamic> miniWorldJson = {
  'id': 'mini',
  'chars': [
    {'id': 'innkeeper', 'theory': 'bigfive', 'unlockAt': 0},
    {'id': 'smith', 'theory': 'holland', 'unlockAt': 2},
    {
      'id': 'hermit',
      'theory': 'values',
      'unlockAt': 4,
      'requires': {'innkeeper': 3},
    },
  ],
  'theories': [
    {
      'id': 'bigfive',
      'mode': 'dominant',
      'axes': [
        ['O+', 'O-'],
        ['C+', 'C-'],
        ['E+', 'E-'],
        ['A+', 'A-'],
        ['N+', 'N-'],
      ],
    },
    {
      'id': 'holland',
      'mode': 'dominant',
      'axes': [
        ['R'],
        ['I'],
        ['A'],
        ['S'],
        ['E'],
        ['C'],
      ],
    },
    {
      'id': 'values',
      'mode': 'dominant',
      'axes': [
        ['power'],
        ['care'],
        ['freedom'],
      ],
    },
    {
      'id': 'type16',
      'mode': 'code',
      'axes': [
        ['E', 'I'],
        ['S', 'N'],
        ['T', 'F'],
        ['J', 'P'],
      ],
      'measures': 'bigfive',
      'poleAlias': {
        'E+': 'E',
        'E-': 'I',
        'O+': 'N',
        'O-': 'S',
        'A+': 'F',
        'A-': 'T',
        'C+': 'J',
        'C-': 'P',
      },
    },
  ],
  'frames': [
    {
      'id': 'f_help',
      'axes': ['who', 'where'],
      'choices': [
        {
          'id': 'c1',
          'traits': {
            'bigfive': ['O+'],
          },
        },
        {
          'id': 'c2',
          'traits': {
            'bigfive': ['C+'],
          },
        },
        {
          'id': 'c3',
          'traits': {
            'bigfive': ['E+'],
          },
        },
      ],
    },
    {
      'id': 'f_trade',
      'axes': ['who'],
      'choices': [
        {
          'id': 'c1',
          'traits': {
            'bigfive': ['A+'],
          },
        },
        {
          'id': 'c2',
          'traits': {
            'bigfive': ['N+'],
          },
        },
        {
          'id': 'c3',
          'traits': {
            'bigfive': ['E-'],
          },
        },
      ],
    },
    {
      'id': 'f_lost',
      'axes': ['who', 'where'],
      'choices': [
        {
          'id': 'c1',
          'traits': {
            'holland': ['R'],
          },
        },
        {
          'id': 'c2',
          'traits': {
            'holland': ['I'],
          },
        },
        {
          'id': 'c3',
          'traits': {
            'holland': ['A'],
          },
        },
      ],
    },
    {
      'id': 'f_feast',
      'axes': ['who'],
      'choices': [
        {
          'id': 'c1',
          'traits': {
            'holland': ['S'],
          },
        },
        {
          'id': 'c2',
          'traits': {
            'holland': ['E'],
          },
        },
        {
          'id': 'c3',
          'traits': {
            'holland': ['C'],
          },
        },
      ],
    },
    {
      'id': 'f_duel',
      'axes': ['who', 'where'],
      'choices': [
        {
          'id': 'c1',
          'traits': {
            'values': ['power'],
          },
        },
        {
          'id': 'c2',
          'traits': {
            'values': ['care'],
          },
        },
        {
          'id': 'c3',
          'traits': {
            'values': ['freedom'],
          },
        },
      ],
    },
    {
      'id': 'f_secret',
      'axes': ['who'],
      'choices': [
        {
          'id': 'c1',
          'traits': {
            'values': ['power'],
          },
        },
        {
          'id': 'c2',
          'traits': {
            'values': ['care'],
          },
        },
        {
          'id': 'c3',
          'traits': {
            'values': ['freedom'],
          },
        },
      ],
    },
  ],
  'variants': {
    'who': ['stranger', 'friend', 'elder'],
    'where': ['inn', 'market', 'road'],
  },
  'events': [
    {
      'id': 'old_friends',
      'char': 'hermit',
      'met': {'innkeeper': 3},
      'reveals': [
        ['innkeeper', 'hermit'],
      ],
    },
  ],
  'links': [
    ['innkeeper', 'smith'],
  ],
};

/// 테스트 인물의 한국어 이름. 목록에 없는 인물은 `인물<n>`.
const storyCharacterNames = {
  'innkeeper': '객잔 주인',
  'smith': '대장장이',
  'hermit': '은거기인',
};

/// 이론이 낼 수 있는 결과 전부. dominant 는 극, code 는 축 조합 (별칭 적용).
List<String> theoryOutcomes(Theory theory) {
  final raw = switch (theory.mode) {
    TheoryMode.dominant => [for (final axis in theory.axes) ...axis],
    TheoryMode.code => theory.axes.fold<List<String>>(
      [''],
      (acc, axis) => [
        for (final a in acc)
          for (final p in axis) '$a$p',
      ],
    ),
  };
  return [for (final r in raw) theory.outcomeAlias[r] ?? r];
}

/// [world] 의 이야기 문장 전부. 값은 한국어와 숫자로만 써서
/// 이론 코드(C+, ENFJ 등)나 관계 이름이 섞이지 않게 한다.
/// 인물 배경(art)은 첫 인물만 둬서 나머지는 채널 art 로 대체되게 한다.
TextBook storyTextFor(StoryWorld world) {
  final p = 'story.${world.id}';
  final e = <String, String>{
    '$p.name': '작은 강호',
    '$p.style': '세계 말투',
    '$p.avoid': '그녀|소저',
    '$p.ctx.past': '지난번 근거 {choice}',
    '$p.ctx.rumor': '소문 출처 {source}',
    '$p.reveal.confirmed': '역시 접두',
    '$p.reveal.surprised': '의외 접두',
  };
  for (final (i, r) in Relationship.values.indexed) {
    e['$p.rel.${r.name}.style'] = '관계 말투 $i';
    e['$p.ctx.rel.${r.name}'] = '관계 문장 $i';
  }
  for (final (i, t) in JudgmentTone.values.indexed) {
    e['$p.ctx.tone.${t.name}'] = '흐름 문장 $i';
  }
  for (final (ci, c) in world.characters.indexed) {
    final name = storyCharacterNames[c.id] ?? '인물$ci';
    final k = '$p.char.${c.id}';
    e.addAll({
      '$k.name': name,
      '$k.place': '$name의 자리',
      if (ci == 0) '$k.art': '${c.id}_art',
      if (ci == 0) '$k.reveal.confirmed': '$name 역시',
      '$k.style': '$name 말투',
      '$k.reveal': '$name 왈 너는 {title}',
      '$k.intro.first': '$name 첫 만남',
      '$k.intro.rumor': '$name 소문 들음 {source}',
    });
    for (final (i, r) in Relationship.values.indexed) {
      e['$k.intro.again.${r.name}'] = '$name 다시 만남 $i';
    }
    final theory = world.theoryById(c.theoryId);
    if (theory == null) continue;
    for (final (oi, o) in theoryOutcomes(theory).indexed) {
      e['$k.title.$o'] = '$name 칭호 $oi';
      e['$k.saying.$o'] = '$name 맺음 $oi';
    }
  }
  for (final (fi, f) in world.frames.indexed) {
    e['$p.${f.id}'] = [
      '질문 $fi',
      for (final a in f.axes) '{$a}',
    ].join(' ');
    for (final (ci, c) in f.choices.indexed) {
      e['$p.${f.id}.${c.id}'] = '선택 $fi-$ci';
      e['$p.${f.id}.recall.${c.id}'] = '연결 $fi-$ci';
    }
  }
  for (final (ai, axis) in world.variants.entries.indexed) {
    for (final (vi, v) in axis.value.indexed) {
      e['$p.var.${axis.key}.$v'] = '변주 $ai-$vi';
    }
  }
  for (final (i, ev) in world.events.indexed) {
    e['$p.event.${ev.id}.intro'] = '사건 도입 $i';
  }
  for (final (ti, t) in world.theories.indexed) {
    e['theory.${t.id}.name'] = '이론 $ti';
    for (final (pi, pole) in [for (final a in t.axes) ...a].indexed) {
      e['theory.${t.id}.$pole.label'] = '성향 $ti-$pi';
    }
    for (final (oi, o) in theoryOutcomes(t).indexed) {
      // dominant 이론은 결과가 곧 극이라 극 이름을 그대로 둔다.
      e.putIfAbsent('theory.${t.id}.$o.label', () => '유형 $ti-$oi');
      e['theory.${t.id}.$o.desc'] = '유형 $ti-$oi 설명';
      e['theory.${t.id}.$o.strength'] = '유형 $ti-$oi 장점';
      e['theory.${t.id}.$o.weakness'] = '유형 $ti-$oi 약점';
    }
  }
  return TextBook(languageCode: 'ko', entries: e);
}

/// [miniWorld] 를 조립하는 데 필요한 이야기 문장 전부.
final miniStoryText = storyTextFor(miniWorld);

/// 메모리 이야기 저장소 (실제 동작하는 대체 구현).
class InMemoryStoryRepository implements StoryRepository {
  InMemoryStoryRepository([Map<String, List<StoryMeeting>>? meetings])
    : meetings = meetings ?? {};

  final Map<String, List<StoryMeeting>> meetings;
  bool failAppend = false;

  @override
  Future<Result<List<StoryMeeting>>> load(String worldId) async =>
      Success(List.unmodifiable(meetings[worldId] ?? const <StoryMeeting>[]));

  @override
  Future<Result<void>> append(String worldId, StoryMeeting meeting) async {
    if (failAppend) {
      return const ErrorResult(LocalStorageFailure(message: 'append'));
    }
    meetings[worldId] = [...?meetings[worldId], meeting];
    return const Success(null);
  }

  @override
  Future<Result<void>> clear() async {
    meetings.clear();
    return const Success(null);
  }
}
