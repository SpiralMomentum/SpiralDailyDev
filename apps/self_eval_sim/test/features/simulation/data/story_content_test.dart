import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/data/story/story_world_mapper.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/catalog.dart';
import 'package:self_eval_sim/features/simulation/domain/story/frame_picker.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_judge.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_ledger.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_world.dart';

import '../../../support/story_fixtures.dart';

/// 무협 이야기 세계의 실제 에셋(world.json, ko.json)을 검사한다.
/// 번들 없이 돌도록 파일로 직접 읽는다.
const _worldPath = 'assets/story/wuxia/world.json';
const _storyKoPath = 'assets/story/wuxia/ko.json';
const _baseKoPath = 'assets/content/strings/ko.json';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Map<String, String> _strings(String path) =>
    _json(path).map((k, v) => MapEntry(k, v as String));

/// 설계 4절 표: id -> (이론, 해금, 선행 조건).
const _table = <String, (String, int, Map<String, int>)>{
  'innkeeper': ('bigfive', 0, {}),
  'smith': ('holland', 2, {}),
  'escort': ('conflict', 4, {}),
  'physiognomist': ('type16', 6, {}),
  'physician': ('temperament', 8, {}),
  'ronin': ('sensation', 10, {}),
  'strategist': ('regfocus', 13, {}),
  'diviner': ('locus', 16, {}),
  'hermit': ('values', 20, {'innkeeper': 3}),
  'sectleader': ('honesty', 24, {'hermit': 2}),
  'demonlord': ('moral', 30, {'hermit': 3, 'sectleader': 1}),
};

const _newTheories = [
  'holland',
  'conflict',
  'sensation',
  'regfocus',
  'locus',
  'values',
  'honesty',
  'moral',
];

/// 브리프의 이론 정의: id -> (방식, 축).
const _theoryShapes = <String, (TheoryMode, List<List<String>>)>{
  'bigfive': (
    TheoryMode.dominant,
    [
      ['O+', 'O-'],
      ['C+', 'C-'],
      ['E+', 'E-'],
      ['A+', 'A-'],
      ['N+', 'N-'],
    ],
  ),
  'holland': (
    TheoryMode.dominant,
    [
      ['R'],
      ['I'],
      ['A'],
      ['S'],
      ['E'],
      ['C'],
    ],
  ),
  'conflict': (
    TheoryMode.dominant,
    [
      ['compete'],
      ['collaborate'],
      ['compromise'],
      ['avoid'],
      ['accommodate'],
    ],
  ),
  'type16': (
    TheoryMode.code,
    [
      ['E', 'I'],
      ['S', 'N'],
      ['T', 'F'],
      ['J', 'P'],
    ],
  ),
  'temperament': (
    TheoryMode.code,
    [
      ['E+', 'E-'],
      ['N+', 'N-'],
    ],
  ),
  'sensation': (
    TheoryMode.code,
    [
      ['TAS+', 'TAS-'],
      ['DIS+', 'DIS-'],
    ],
  ),
  'regfocus': (
    TheoryMode.dominant,
    [
      ['promotion', 'prevention'],
    ],
  ),
  'locus': (
    TheoryMode.dominant,
    [
      ['internal', 'external'],
    ],
  ),
  'values': (
    TheoryMode.dominant,
    [
      ['SD'],
      ['ST'],
      ['HE'],
      ['AC'],
      ['PO'],
      ['SE'],
      ['CO'],
      ['TR'],
      ['BE'],
      ['UN'],
    ],
  ),
  'honesty': (
    TheoryMode.dominant,
    [
      ['H+', 'H-'],
    ],
  ),
  'moral': (
    TheoryMode.dominant,
    [
      ['care'],
      ['fairness'],
      ['loyalty'],
      ['authority'],
      ['sanctity'],
    ],
  ),
};

/// 이론별 결과 수 (설계 7절).
const _outcomeCounts = {
  'bigfive': 10,
  'holland': 6,
  'conflict': 5,
  'type16': 16,
  'temperament': 4,
  'sensation': 4,
  'regfocus': 2,
  'locus': 2,
  'values': 10,
  'honesty': 2,
  'moral': 5,
};

/// 화면에 보이면 안 되는 이론 이름 (한국어/영어 표기).
const _theoryNames = [
  '빅파이브',
  '5요인',
  '홀랜드',
  '직업흥미',
  '직업 흥미',
  '이중관심',
  '16유형',
  '4기질',
  '기질설',
  '감각추구',
  '조절초점',
  '통제소재',
  '통제위치',
  '슈워츠',
  '정직-겸손',
  '도덕 기반',
  '도덕기반',
  '에니어그램',
];

/// 화면에 보이면 안 되는 관계 이름.
const _relationshipNames = ['친구', '연인', '악연', '라이벌', '원수', '적수'];

/// 영문자와 `+` 는 유형 코드(INTJ, E+ 등)의 흔적이다.
final _code = RegExp(r'[A-Za-z+]');
final _emoji = RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);

/// 변주 축 (설계 6절).
const _variantAxes = ['who', 'where', 'stake'];

final _placeholder = RegExp(r'\{(\w+)\}');

Set<String> _placeholders(String s) => {
  for (final m in _placeholder.allMatches(s)) m.group(1)!,
};

/// 자리표시자 바로 뒤에는 받침과 무관한 조사나 띄어쓰기/문장부호만 온다.
/// (이/가, 을/를, 은/는, 와/과 같은 조사는 변주 문장의 받침에 따라 틀린다.)
final _badParticle = RegExp(r'\{\w+\}(?!의|에|하고|도|까지|만|[ ,.?]|$)');

void main() {
  late StoryWorld world;
  late Map<String, String> story;
  late Map<String, String> merged;

  setUpAll(() {
    world = StoryWorldMapper.fromJson(_json(_worldPath));
    story = _strings(_storyKoPath);
    merged = {..._strings(_baseKoPath), ...story};
  });

  const w = 'story.wuxia';

  String charKey(String id, String rest) => '$w.char.$id.$rest';

  /// 인물의 화면 고정 문장 키 전부 (말투 style 은 프롬프트 전용이라 뺀다).
  List<String> fixedKeys(StoryCharacter c) {
    final theory = world.theoryById(c.theoryId)!;
    return [
      charKey(c.id, 'name'),
      charKey(c.id, 'place'),
      charKey(c.id, 'reveal'),
      charKey(c.id, 'intro.first'),
      charKey(c.id, 'intro.rumor'),
      // 다시 만난 결과 첫 줄 접두 (인물 말투).
      charKey(c.id, 'reveal.confirmed'),
      charKey(c.id, 'reveal.surprised'),
      for (final r in Relationship.values)
        charKey(c.id, 'intro.again.${r.name}'),
      for (final o in theoryOutcomes(theory)) ...[
        charKey(c.id, 'title.$o'),
        charKey(c.id, 'saying.$o'),
      ],
    ];
  }

  /// 틀(질문, 선택지, 연결 문장)과 변주 문장 키 전부.
  List<String> frameKeys() => [
    for (final f in world.frames) ...[
      '$w.${f.id}',
      for (final c in f.choices) ...[
        '$w.${f.id}.${c.id}',
        '$w.${f.id}.recall.${c.id}',
      ],
    ],
    for (final e in world.variants.entries)
      for (final v in e.value) '$w.var.${e.key}.$v',
  ];

  /// 이론의 모든 극.
  Set<String> polesOf(Theory t) => {
    for (final a in t.axes)
      for (final p in a) p,
  };

  /// 태그 원천 이론 (자기 태그로 측정하는 이론).
  List<Theory> tagSources() =>
      world.theories.where((t) => t.measures == null).toList();

  /// 아무 처지 없이(무공 입문 전) 인물이 쓸 수 있는 틀.
  List<StoryFrame> freshFramesFor(StoryCharacter c) {
    final source = world.theoryById(c.theoryId)!.tagSource;
    return world.frames
        .where(
          (f) =>
              f.requiresStatus.isEmpty &&
              f.choices.any((ch) => (ch.traits[source] ?? const []).isNotEmpty),
        )
        .toList();
  }

  /// 화면에 보일 수 있는 모든 고정 문장 (인물, 사건, 세계 이름, 새 이론 프로필, 틀, 변주).
  List<(String, String)> visibleTexts() => [
    for (final c in world.characters)
      for (final k in fixedKeys(c)) (k, story[k] ?? ''),
    for (final e in world.events)
      ('$w.event.${e.id}.intro', story['$w.event.${e.id}.intro'] ?? ''),
    ('$w.name', story['$w.name'] ?? ''),
    for (final t in ['confirmed', 'surprised'])
      ('$w.reveal.$t', story['$w.reveal.$t'] ?? ''),
    for (final t in _newTheories)
      for (final o in theoryOutcomes(world.theoryById(t)!))
        for (final f in ['label', 'desc', 'strength', 'weakness'])
          ('theory.$t.$o.$f', story['theory.$t.$o.$f'] ?? ''),
    for (final k in frameKeys()) (k, story[k] ?? ''),
  ];

  test('실제 world.json 이 StoryWorldMapper 로 읽힌다', () {
    expect(() => StoryWorldMapper.fromJson(_json(_worldPath)), returnsNormally);
    expect(world.id, 'wuxia');
  });

  test('세계 구조: 인물 11명, 위 표의 이론/해금 값', () {
    expect(world.characters.map((c) => c.id), _table.keys);
    for (final c in world.characters) {
      final (theory, unlockAt, requires) = _table[c.id]!;
      expect(c.theoryId, theory, reason: c.id);
      expect(c.unlockAt, unlockAt, reason: c.id);
      expect(c.requires, requires, reason: c.id);
    }
  });

  test('이론 정의가 브리프 값과 같다', () {
    Theory t(String id) => world.theoryById(id)!;
    expect(
      world.theories.map((t) => t.id).toSet(),
      _outcomeCounts.keys.toSet(),
    );
    for (final e in _theoryShapes.entries) {
      expect(t(e.key).mode, e.value.$1, reason: e.key);
      expect(t(e.key).axes, e.value.$2, reason: e.key);
    }
    expect(t('type16').measures, 'bigfive');
    expect(t('type16').poleAlias, {
      'E+': 'E',
      'E-': 'I',
      'O+': 'N',
      'O-': 'S',
      'A+': 'F',
      'A-': 'T',
      'C+': 'J',
      'C-': 'P',
    });
    expect(t('temperament').measures, 'bigfive');
    expect(t('temperament').outcomeAlias, {
      'E+N-': 'sanguine',
      'E+N+': 'choleric',
      'E-N+': 'melancholic',
      'E-N-': 'phlegmatic',
    });
    for (final e in _outcomeCounts.entries) {
      expect(theoryOutcomes(t(e.key)).toSet().length, e.value, reason: e.key);
    }
    expect(_outcomeCounts.values.fold<int>(0, (a, b) => a + b), 66);
  });

  test('사건 5개와 안면 관계', () {
    final events = {for (final e in world.events) e.id: e};
    expect(events.keys, [
      'old_friends',
      'martial_start',
      'escort_job',
      'sect_gate',
      'demon_shadow',
    ]);
    expect(
      {for (final e in world.events) e.id: e.characterId},
      {
        'old_friends': 'hermit',
        'martial_start': 'hermit',
        'escort_job': 'escort',
        'sect_gate': 'sectleader',
        'demon_shadow': 'demonlord',
      },
    );
    expect(events['old_friends']!.met, {'innkeeper': 3});
    expect(events['old_friends']!.reveals, [('innkeeper', 'hermit')]);
    expect(events['martial_start']!.met, {'hermit': 2});
    expect(events['martial_start']!.grantsStatus, 'martial');
    expect(events['escort_job']!.minMeetings, 0);
    expect(events['escort_job']!.grantsStatus, 'escort');
    expect(events['sect_gate']!.requiresStatus, {'martial'});
    expect(events['demon_shadow']!.reveals, [('demonlord', 'hermit')]);
    expect(world.links, [
      ('innkeeper', 'smith'),
      ('innkeeper', 'physiognomist'),
      ('physician', 'diviner'),
      ('escort', 'ronin'),
      ('strategist', 'sectleader'),
    ]);
  });

  test('모든 인물의 이론이 세계 이론 목록에 있다', () {
    for (final c in world.characters) {
      expect(world.theoryById(c.theoryId), isNotNull, reason: c.id);
    }
  });

  test('인물마다 필요한 문장 키가 모두 있고 비어 있지 않다', () {
    var titles = 0;
    for (final c in world.characters) {
      for (final k in [...fixedKeys(c), charKey(c.id, 'style')]) {
        expect(story[k]?.trim(), isNotEmpty, reason: k);
      }
      titles += theoryOutcomes(world.theoryById(c.theoryId)!).length;
      expect(story[charKey(c.id, 'reveal')], contains('{title}'));
      expect(story[charKey(c.id, 'intro.rumor')], contains('{source}'));
    }
    expect(titles, 66);
  });

  test('같은 결과의 맺음 문장은 칭호를 되풀이하지 않는다', () {
    for (final c in world.characters) {
      for (final o in theoryOutcomes(world.theoryById(c.theoryId)!)) {
        final title = story[charKey(c.id, 'title.$o')]!;
        final saying = story[charKey(c.id, 'saying.$o')]!;
        expect(saying.contains(title), isFalse, reason: '${c.id} $o: $saying');
      }
    }
  });

  test('재회 결과 접두는 짧은 한 문장이고 칭호 자리표시자가 없다', () {
    for (final c in world.characters) {
      for (final t in ['confirmed', 'surprised']) {
        final v = story[charKey(c.id, 'reveal.$t')]!;
        expect(v.length, lessThanOrEqualTo(20), reason: '${c.id} $t: $v');
        expect(v.contains('{'), isFalse, reason: '${c.id} $t: $v');
      }
    }
  });

  test('표국 일(escort 상태) 틀이 3개 이상이고 escort_job 이 그 상태를 준다', () {
    final escort = world.frames
        .where((f) => f.requiresStatus.contains('escort'))
        .toList();
    expect(escort.length, greaterThanOrEqualTo(3));
    expect(
      world.events.where((e) => e.grantsStatus == 'escort').map((e) => e.id),
      ['escort_job'],
    );
  });

  test('세계, 관계, 맥락, 사건 문장 키가 모두 있다', () {
    final keys = [
      '$w.name',
      '$w.reveal.confirmed',
      '$w.reveal.surprised',
      '$w.style',
      '$w.avoid',
      '$w.ctx.past',
      '$w.ctx.rumor',
      for (final r in Relationship.values) ...[
        '$w.rel.${r.name}.style',
        '$w.ctx.rel.${r.name}',
      ],
      for (final t in JudgmentTone.values) '$w.ctx.tone.${t.name}',
      for (final e in world.events) '$w.event.${e.id}.intro',
    ];
    for (final k in keys) {
      expect(story[k]?.trim(), isNotEmpty, reason: k);
    }
    expect(story['$w.ctx.past'], contains('{choice}'));
    expect(story['$w.ctx.rumor'], contains('{source}'));
  });

  test('새 이론의 결과마다 프로필 4문장이 있다', () {
    for (final id in _newTheories) {
      final theory = world.theoryById(id)!;
      expect(story['theory.$id.name']?.trim(), isNotEmpty, reason: id);
      for (final o in theoryOutcomes(theory)) {
        for (final f in ['label', 'desc', 'strength', 'weakness']) {
          final k = 'theory.$id.$o.$f';
          expect(story[k]?.trim(), isNotEmpty, reason: k);
        }
      }
    }
  });

  test('모든 이론의 극 이름과 결과 프로필이 합친 문장에 있다', () {
    for (final theory in world.theories) {
      final poles = {
        for (final a in theory.axes)
          for (final p in a) p,
      };
      for (final p in poles) {
        final k = 'theory.${theory.id}.$p.label';
        expect(merged[k]?.trim(), isNotEmpty, reason: k);
      }
      for (final o in theoryOutcomes(theory)) {
        for (final f in ['desc', 'strength', 'weakness']) {
          final k = 'theory.${theory.id}.$o.$f';
          expect(merged[k]?.trim(), isNotEmpty, reason: k);
        }
      }
    }
  });

  test('금지 표현 정규식이 컴파일되고, 인물 고정 문장 어디에도 금지 표현이 없다', () {
    final avoid = RegExp(story['$w.avoid']!);
    for (final word in [
      '그녀',
      '소저',
      '소협',
      '형님',
      '누이',
      '오라버니',
      '자네',
      '그대',
      '그대여',
      '하오.',
      '성질의 것',
    ]) {
      expect(avoid.hasMatch(word), isTrue, reason: word);
    }
    // '그대로'는 흔한 말이라 걸리면 안 된다 (animal.avoid 와 같은 규칙).
    expect(avoid.hasMatch('그대로'), isFalse);
    expect(avoid.hasMatch('본 그대로 말한다'), isFalse);
    for (final (k, v) in visibleTexts()) {
      expect(avoid.hasMatch(v), isFalse, reason: '$k: $v');
      expect(_emoji.hasMatch(v), isFalse, reason: '$k: $v');
    }
  });

  test('고정 문장에 이론 이름, 유형 코드, 관계 이름이 없다', () {
    for (final (k, v) in visibleTexts()) {
      // 자리표시자({title}, {source}, 변주 축)는 화면에 나가기 전에 채워진다.
      final shown = v.replaceAll(
        RegExp(r'\{(title|source|who|where|stake)\}'),
        '',
      );
      expect(_code.hasMatch(shown), isFalse, reason: '$k: $v');
      for (final name in [..._theoryNames, ..._relationshipNames]) {
        expect(v.contains(name), isFalse, reason: '$k: $v ($name)');
      }
    }
  });

  test('틀 40개 이상: id 는 f_, 선택지 3개, 선택지마다 2개 이상 이론에 태그, 극은 이론 축에 있다', () {
    expect(world.frames.length, greaterThanOrEqualTo(40));
    expect(world.frames.map((f) => f.id).toSet().length, world.frames.length);
    final sources = {for (final t in tagSources()) t.id: t};
    for (final f in world.frames) {
      expect(f.id, startsWith('f_'));
      expect(f.choices.map((c) => c.id), ['c1', 'c2', 'c3'], reason: f.id);
      for (final c in f.choices) {
        final tagged = c.traits.entries.where((e) => e.value.isNotEmpty);
        expect(
          tagged.length,
          greaterThanOrEqualTo(2),
          reason: '${f.id}.${c.id}',
        );
        for (final e in c.traits.entries) {
          expect(sources.keys, contains(e.key), reason: '${f.id}.${c.id}');
          expect(
            polesOf(sources[e.key]!),
            containsAll(e.value),
            reason: '${f.id}.${c.id} ${e.key}',
          );
        }
      }
    }
  });

  test('한 틀 안에서 선택지의 태그 묶음은 서로 다르다', () {
    String key(FrameChoice c) =>
        (c.traits.entries
                .where((e) => e.value.isNotEmpty)
                .map((e) => '${e.key}:${([...e.value]..sort()).join(',')}')
                .toList()
              ..sort())
            .join(' ');
    for (final f in world.frames) {
      final keys = f.choices.map(key).toList();
      expect(keys.toSet(), hasLength(keys.length), reason: '${f.id} $keys');
    }
  });

  test('한 틀 안에서 이론별 태그가 세 선택지 모두 같지는 않다', () {
    for (final f in world.frames) {
      final theories = {for (final c in f.choices) ...c.traits.keys};
      for (final t in theories) {
        final tags = {
          for (final c in f.choices) ([...?c.traits[t]]..sort()).join(','),
        };
        expect(tags.length, greaterThan(1), reason: '${f.id} $t');
      }
    }
  });

  test('태그 원천 이론마다 무공 입문 전 틀 12개 이상, martial 틀 6개 이상, 극마다 입문 전 선택지 8개 이상', () {
    final granted = {
      for (final e in world.events)
        if (e.grantsStatus != null) e.grantsStatus!,
    };
    for (final f in world.frames) {
      expect(granted, containsAll(f.requiresStatus), reason: f.id);
      expect(granted, containsAll(f.forbidsStatus), reason: f.id);
    }
    final fresh = world.frames.where((f) => f.requiresStatus.isEmpty);
    for (final t in tagSources()) {
      final n = fresh
          .where(
            (f) =>
                f.choices.any((c) => (c.traits[t.id] ?? const []).isNotEmpty),
          )
          .length;
      expect(n, greaterThanOrEqualTo(12), reason: t.id);
      for (final p in polesOf(t)) {
        final uses = [
          for (final f in fresh)
            for (final c in f.choices)
              if ((c.traits[t.id] ?? const []).contains(p)) c,
        ].length;
        expect(uses, greaterThanOrEqualTo(8), reason: '${t.id} $p');
      }
    }
    expect(
      world.frames.where((f) => f.requiresStatus.contains('martial')).length,
      greaterThanOrEqualTo(6),
    );
  });

  test('변주 축 who/where/stake 각 5개 이상, 틀마다 축 1~3개', () {
    expect(world.variants.keys.toSet(), _variantAxes.toSet());
    for (final a in _variantAxes) {
      expect(world.variants[a]!.length, greaterThanOrEqualTo(5), reason: a);
      expect(world.variants[a]!.toSet().length, world.variants[a]!.length);
    }
    for (final f in world.frames) {
      expect(f.axes.length, inInclusiveRange(1, 3), reason: f.id);
      expect(f.axes.toSet().length, f.axes.length, reason: f.id);
      expect(_variantAxes, containsAll(f.axes), reason: f.id);
    }
  });

  test('모든 틀/선택지/연결 문장/변주 문장 키가 있고 비어 있지 않다', () {
    for (final k in frameKeys()) {
      expect(story[k]?.trim(), isNotEmpty, reason: k);
    }
  });

  test('질문 자리표시자는 틀의 축과 같고, 선택지에는 없으며, 조사는 받침과 무관하다', () {
    for (final f in world.frames) {
      final q = story['$w.${f.id}']!;
      expect(_placeholders(q), f.axes.toSet(), reason: '${f.id}: $q');
      expect(_badParticle.hasMatch(q), isFalse, reason: '${f.id}: $q');
      for (final c in f.choices) {
        final choice = story['$w.${f.id}.${c.id}']!;
        expect(_placeholders(choice), isEmpty, reason: '${f.id}.${c.id}');
        expect(choice.contains('{'), isFalse, reason: '${f.id}.${c.id}');
        final recall = story['$w.${f.id}.recall.${c.id}']!;
        expect(
          f.axes.toSet(),
          containsAll(_placeholders(recall)),
          reason: '${f.id}.recall.${c.id}',
        );
        expect(_badParticle.hasMatch(recall), isFalse, reason: recall);
      }
    }
    // 변주 문장 안에는 자리표시자가 없다.
    for (final e in world.variants.entries) {
      for (final v in e.value) {
        expect(story['$w.var.${e.key}.$v']!.contains('{'), isFalse);
      }
    }
  });

  test('모든 인물은 첫 만남에서 질문 4개를 받고, 쓸 수 있는 틀이 이론의 모든 극을 덮는다', () {
    final ledger = StoryLedger.of(world, const []);
    for (final c in world.characters) {
      for (var seed = 0; seed < 5; seed++) {
        final picked = FramePicker.pick(world, ledger, c, Random(seed));
        expect(picked, hasLength(4), reason: c.id);
        expect(picked.map((p) => p.frame.id).toSet(), hasLength(4));
      }
      final theory = world.theoryById(c.theoryId)!;
      final covered = {
        for (final f in freshFramesFor(c))
          for (final ch in f.choices) ...StoryJudge.poles(theory, ch),
      };
      expect(covered, containsAll(polesOf(theory)), reason: c.id);
    }
    // 관상가(E/O/A/C)와 의원(E/N)은 따로 짚는다.
    for (final (id, poles) in [
      ('physiognomist', ['E', 'I', 'S', 'N', 'T', 'F', 'J', 'P']),
      ('physician', ['E+', 'E-', 'N+', 'N-']),
    ]) {
      final c = world.characters.firstWhere((c) => c.id == id);
      final theory = world.theoryById(c.theoryId)!;
      final covered = {
        for (final f in freshFramesFor(c))
          for (final ch in f.choices) ...StoryJudge.poles(theory, ch),
      };
      expect(covered, containsAll(poles), reason: id);
    }
  });

  test('무작위로 답하는 사용자 2000명의 첫 만남 결과가 한쪽으로 쏠리지 않는다', () {
    final ledger = StoryLedger.of(world, const []);
    Map<String, int> firstMeetings(String characterId, int seed) {
      final c = world.characters.firstWhere((c) => c.id == characterId);
      final theory = world.theoryById(c.theoryId)!;
      final random = Random(seed);
      final out = <String, int>{};
      for (var i = 0; i < 2000; i++) {
        final picked = FramePicker.pick(world, ledger, c, random);
        final votes = [
          for (final p in picked)
            (
              poles: StoryJudge.poles(
                theory,
                p.frame.choices[random.nextInt(p.frame.choices.length)],
              ),
              weight: 1.0,
            ),
        ];
        final outcome = StoryJudge.score(theory, votes).outcome;
        out[outcome] = (out[outcome] ?? 0) + 1;
      }
      return out;
    }

    // 주도 방식 인물도 한 결과가 40% 를 넘지 않는다.
    for (final (id, seed) in [
      ('innkeeper', 3),
      ('escort', 5),
      ('demonlord', 13),
    ]) {
      final counts = firstMeetings(id, seed);
      for (final e in counts.entries) {
        expect(e.value / 2000, lessThanOrEqualTo(0.40), reason: '$id $counts');
      }
    }

    final temperament = firstMeetings('physician', 7);
    for (final e in temperament.entries) {
      expect(e.value / 2000, lessThanOrEqualTo(0.45), reason: '$temperament');
    }
    final type16 = firstMeetings('physiognomist', 11);
    for (var i = 0; i < 4; i++) {
      final letters = <String, int>{};
      for (final e in type16.entries) {
        letters[e.key[i]] = (letters[e.key[i]] ?? 0) + e.value;
      }
      for (final e in letters.entries) {
        expect(e.value / 2000, lessThanOrEqualTo(0.70), reason: '$i $letters');
      }
    }
  });
}
