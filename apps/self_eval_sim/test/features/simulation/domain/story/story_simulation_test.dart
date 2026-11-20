import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/data/story/story_world_mapper.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/catalog.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/text_book.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_composer.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_judge.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_text.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_use_cases.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_world.dart';

import '../../../../support/fixtures.dart';
import '../../../../support/story_fixtures.dart';

/// 모델 없이 정책만으로 무협 이야기 60회를 돌려 설계 12절 지표를 잰다 (실제 에셋, 실제 유스케이스).
///
/// 가상 사용자 (시드 2026):
/// - consistent: 만나는 인물의 이론 기준으로 정해 둔 선호 극을 가장 많이 담은 선택지를 고른다.
/// - random: 균등 무작위.
/// - drifting: consistent 와 같되 만남 20회마다 선호 극을 새로 뽑는다.
const _meetings = 60;
const _seed = 2026;

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

final StoryWorld _world = StoryWorldMapper.fromJson(
  _json('assets/story/wuxia/world.json'),
);
final TextBook _text = TextBook(
  languageCode: 'ko',
  entries: _json(
    'assets/story/wuxia/ko.json',
  ).map((k, v) => MapEntry(k, v as String)),
);

enum _User { consistent, random, drifting }

/// 이론마다 선호 극. 양극 축 이론(빅파이브, 16상 등)은 축마다 극 하나,
/// 단극 범주 이론(홀랜드, 갈등 방식 등)은 범주 하나.
Map<String, Set<String>> _preferences(Random random) => {
  for (final t in _world.theories)
    t.id: t.axes.every((a) => a.length > 1)
        ? {for (final axis in t.axes) axis[random.nextInt(axis.length)]}
        : {
            () {
              final poles = [for (final a in t.axes) ...a];
              return poles[random.nextInt(poles.length)];
            }(),
          },
};

/// 선호 극과 같은 극 수 - 같은 축의 반대 극 수. 가장 높은 선택지 중 무작위.
String _consistentChoice(
  Theory theory,
  Set<String> preferred,
  StoryFrame frame,
  Random random,
) {
  int score(FrameChoice c) {
    var s = 0;
    for (final p in StoryJudge.poles(theory, c)) {
      if (preferred.contains(p)) {
        s += 1;
      } else if (theory.axes.any(
        (a) => a.contains(p) && a.any(preferred.contains),
      )) {
        s -= 1;
      }
    }
    return s;
  }

  final best = frame.choices.map(score).reduce(max);
  final top = frame.choices.where((c) => score(c) == best).toList();
  return top[random.nextInt(top.length)].id;
}

final class _Run {
  _Run(this.plans, this.questions);

  final List<MeetingPlan> plans;

  /// 만남마다 화면 문항 문장.
  final List<List<String>> questions;
}

Future<_Run> _simulate(_User user) async {
  final story = InMemoryStoryRepository();
  final acc = InMemoryAccumulationRepository();
  final app = Random(_seed);
  final pick = Random(_seed);
  var preferred = _preferences(pick);
  final start = StartMeetingUseCase(story, app);
  final plan = PlanMeetingUseCase(story, acc, app, () => DateTime(2026));
  final plans = <MeetingPlan>[];
  final questions = <List<String>>[];
  for (var i = 0; i < _meetings; i++) {
    if (user == _User.drifting && i > 0 && i % 20 == 0) {
      preferred = _preferences(pick);
    }
    final setup = (await start(_world, _text)).dataOrNull!;
    // 같은 태그를 읽는 이론(16상, 4체질은 빅파이브 태그)은 같은 선호를 쓴다: 한 사람의 성향은 하나다.
    final theory = _world.theoryById(
      _world.theoryById(setup.character.theoryId)!.tagSource,
    )!;
    final choiceIds = [
      for (final p in setup.frames)
        user == _User.random
            ? p.frame.choices[pick.nextInt(p.frame.choices.length)].id
            : _consistentChoice(theory, preferred[theory.id]!, p.frame, pick),
    ];
    questions.add([
      for (final q in StoryComposer.questions(_world, _text, setup)) q.text,
    ]);
    plans.add(
      (await plan(
        world: _world,
        setup: setup,
        choiceIds: choiceIds,
      )).dataOrNull!,
    );
  }
  return _Run(plans, questions);
}

/// 같은 인물의 직전 만남 대비 판단이 바뀐 수와 재만남 수.
(int, int) _flips(List<MeetingPlan> plans) {
  final last = <String, String>{};
  var flips = 0;
  var again = 0;
  for (final p in plans) {
    final id = p.meeting.characterId;
    final prev = last[id];
    if (prev != null) {
      again++;
      if (prev != p.meeting.outcome) flips++;
    }
    last[id] = p.meeting.outcome;
  }
  return (flips, again);
}

void main() {
  late Map<_User, _Run> runs;

  setUpAll(() async {
    runs = {for (final u in _User.values) u: await _simulate(u)};
  });

  test('60회 동안 같은 인물에게 같은 (틀, 변주) 재등장 0 (모든 사용자)', () {
    for (final e in runs.entries) {
      final seen = <String>{};
      var repeats = 0;
      for (final p in e.value.plans) {
        for (final a in p.meeting.answers) {
          if (!seen.add('${p.meeting.characterId}#${a.comboKey}')) repeats++;
        }
      }
      expect(repeats, 0, reason: e.key.name);
    }
  });

  test('한 만남 안에서 장소는 인물 자리이고 대부분 하나, 같은 사람은 두 질문까지 (모든 사용자)', () {
    for (final e in runs.entries) {
      var meetings = 0;
      var maxWho = 0;
      var sameWhere = 0;
      for (final p in e.value.plans) {
        final c = _world.characterById(p.meeting.characterId)!;
        final whoCounts = <String, int>{};
        for (final a in p.meeting.answers) {
          final who = a.variant['who'];
          if (who != null) whoCounts[who] = (whoCounts[who] ?? 0) + 1;
        }
        for (final n in whoCounts.values) {
          if (n > maxWho) maxWho = n;
        }
        final wheres = {for (final a in p.meeting.answers) ?a.variant['where']};
        expect(c.places, containsAll(wheres), reason: '${e.key.name} ${c.id}');
        meetings++;
        if (wheres.length <= 1) sameWhere++;
      }
      // ignore: avoid_print
      print('STORYSIM ${e.key.name} max-who=$maxWho same-where=$sameWhere/$meetings');
      expect(maxWho, lessThanOrEqualTo(2), reason: e.key.name);
      expect(sameWhere / meetings, greaterThanOrEqualTo(0.8), reason: e.key.name);
    }
  });

  test('같은 틀 재등장 시 연결 문장 포함 100% (모든 사용자)', () {
    for (final e in runs.entries) {
      final used = <String, String>{}; // 인물#틀 -> 지난 선택지
      var reappear = 0;
      for (final (i, p) in e.value.plans.indexed) {
        final c = p.meeting.characterId;
        for (final (j, a) in p.meeting.answers.indexed) {
          final prev = used['$c#${a.frameId}'];
          if (prev != null) {
            reappear++;
            final recall = _text.frameRecall(
              _world.id,
              a.frameId,
              prev,
              a.variant,
            );
            expect(
              e.value.questions[i][j],
              startsWith('$recall '),
              reason: '${e.key.name} #${i + 1} $c ${a.frameId}',
            );
          }
          used['$c#${a.frameId}'] = a.choiceId;
        }
      }
      // ignore: avoid_print
      print('STORYSIM ${e.key.name} frame-reappear=$reappear');
    }
  });

  test('consistent 사용자의 같은 인물 판단 뒤집힘 비율 10% 이하', () {
    final (flips, again) = _flips(runs[_User.consistent]!.plans);
    expect(again, greaterThan(0));
    expect(flips / again, lessThanOrEqualTo(0.10), reason: '$flips/$again');
  });

  test('60회 안에 11명 모두 열린다 (consistent)', () {
    final met = {
      for (final p in runs[_User.consistent]!.plans) p.meeting.characterId,
    };
    expect(met, {for (final c in _world.characters) c.id});
  });

  test('사건 5개가 모두 한 번씩 일어난다 (consistent)', () {
    final fired = [
      for (final p in runs[_User.consistent]!.plans)
        if (p.meeting.eventId != null) p.meeting.eventId!,
    ];
    expect(fired, unorderedEquals([for (final e in _world.events) e.id]));
  });

  // 시드 8개(2026, 1~7) 평균 surprised 11.0% (43/392), 이 시드 12.2% (6/49). 재회 중립(neutral)은 분모에 든다. 남는 surprised 는 첫 만남이 소문/동점으로
  // 정해진 판단을 이력 현상이 붙잡고 있는데 이번 답이 반대쪽인 경우다 (의외가 맞다).
  test('consistent 사용자: 다시 만난 판단의 tone 이 대부분 confirmed (surprised 15% 이하)', () {
    final again = [
      for (final p in runs[_User.consistent]!.plans)
        if (p.judgment.tone != JudgmentTone.first) p.judgment.tone,
    ];
    final surprised = again.where((t) => t == JudgmentTone.surprised).length;
    expect(surprised / again.length, lessThanOrEqualTo(0.15));
  });

  test('지표 출력', () {
    for (final e in runs.entries) {
      final plans = e.value.plans;
      final (flips, again) = _flips(plans);
      final firstMet = <String, int>{};
      for (final p in plans) {
        firstMet.putIfAbsent(p.meeting.characterId, () => p.meeting.number);
      }
      final counts = <String, int>{};
      for (final p in plans) {
        counts[p.meeting.characterId] =
            (counts[p.meeting.characterId] ?? 0) + 1;
      }
      final tones = <String, int>{};
      for (final p in plans) {
        tones[p.judgment.tone.name] = (tones[p.judgment.tone.name] ?? 0) + 1;
      }
      final events = {
        for (final p in plans)
          if (p.meeting.eventId != null) p.meeting.eventId!: p.meeting.number,
      };
      final recalls = plans
          .where((p) => p.setup.frames.any((f) => f.recallChoiceId != null))
          .length;
      final rels = <String, int>{};
      for (final p in plans) {
        if (p.meeting.number == firstMet[p.meeting.characterId]) {
          rels[p.meeting.relationship.name] =
              (rels[p.meeting.relationship.name] ?? 0) + 1;
        }
      }
      // ignore: avoid_print
      print(
        'STORYSIM ${e.key.name} flips=$flips/$again tones=$tones '
        'firstMet=$firstMet counts=$counts events=$events '
        'meetingsWithRecall=$recalls rels=$rels',
      );
      // ignore: avoid_print
      print(
        'STORYSIM ${e.key.name} seq=${[for (final p in plans) '${p.meeting.characterId}:${p.meeting.outcome}:${p.judgment.tone.name[0]}'].join(' ')}',
      );
    }
  });
}
