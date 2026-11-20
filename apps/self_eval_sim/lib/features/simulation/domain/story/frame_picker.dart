import 'dart:math';

import '../entities/catalog.dart';
import 'story_judge.dart';
import 'story_ledger.dart';
import 'story_record.dart';
import 'story_world.dart';

/// 고른 질문 틀과 변주. [recallChoiceId] 는 이 인물이 이 틀에서 지난번 고른 선택지다 (재등장일 때만).
final class PickedFrame {
  const PickedFrame({
    required this.frame,
    required this.variant,
    this.recallChoiceId,
  });

  final StoryFrame frame;
  final Map<String, String> variant;
  final String? recallChoiceId;
}

/// 한 만남에 물을 질문 틀을 고르는 정책. 순수 함수다.
abstract final class FramePicker {
  static List<PickedFrame> pick(
    StoryWorld world,
    StoryLedger ledger,
    StoryCharacter character,
    Random random, {
    int count = StoryRules.questionsPerMeeting,
    int gap = StoryRules.frameGap,
    int whoRepeat = 2,
  }) {
    final theory = world.theoryById(character.theoryId);
    if (theory == null) return const [];
    final answers = ledger.answersTo(character.id);
    final usedFrames = {for (final a in answers) a.frameId};
    final recent = ledger.recentFrames(gap).toSet();
    final values = _values(world, character);

    // 변주 축이 비어 조합이 없는 틀은 건너뛴다.
    final candidates = world.frames
        .where(
          (f) =>
              _qualifies(f, theory, ledger.status) &&
              _combos(values, f.axes).isNotEmpty,
        )
        .toList();

    // 안 쓴 틀 < 안 쓴 조합이 남은 틀 < 조합을 다 쓴 틀, 각 단계 안에서 최근 틀은 뒤로.
    // 같은 순위는 무작위.
    int tier(StoryFrame f) {
      if (!usedFrames.contains(f.id)) return 0;
      final used = {
        for (final a in answers)
          if (a.frameId == f.id) a.comboKey,
      };
      final exhausted = _combos(
        values,
        f.axes,
      ).every((c) => used.contains(_key(f, c)));
      return exhausted ? 2 : 1;
    }

    int rank(StoryFrame f) => tier(f) * 2 + (recent.contains(f.id) ? 1 : 0);
    final shuffled = [...candidates]..shuffle(random);
    final ordered = [...shuffled]..sort((a, b) => rank(a).compareTo(rank(b)));
    final chosen = theory.mode == TheoryMode.code
        ? _coverAxes(theory, ordered, rank, count)
        : _fullFirst(theory, ordered, rank).take(count).toList();

    // 한 만남의 질문은 같은 날 같은 곳의 일처럼 읽히도록 축마다 값 하나를 정해 두고,
    // 안 쓴 조합 중 이 값과 많이 겹치는 조합을 고른다.
    // 같은 사람이 매 질문에 나오면 어색하므로 `who` 는 [whoRepeat] 번 쓰면 다른 사람으로 바꾼다.
    final meeting = {
      for (final e in values.entries)
        if (e.value.isNotEmpty) e.key: e.value[random.nextInt(e.value.length)],
    };
    final out = <PickedFrame>[];
    var whoUses = 0;
    for (final f in chosen) {
      final variant = _variantFor(values, f, answers, meeting, random);
      out.add(
        PickedFrame(
          frame: f,
          variant: variant,
          recallChoiceId: _recall(f, answers),
        ),
      );
      final who = variant['who'];
      if (who == null || who != meeting['who']) continue;
      if (++whoUses < whoRepeat) continue;
      final others = [
        for (final v in values['who'] ?? const <String>[])
          if (v != who) v,
      ];
      if (others.isNotEmpty) {
        meeting['who'] = others[random.nextInt(others.length)];
        whoUses = 0;
      }
    }
    return out;
  }

  /// 인물 이론이 실제로 재는 극(별칭을 거친 극이 이론 축에 있는 것)을 태그한 선택지가 있어야 한다.
  static bool _qualifies(StoryFrame f, Theory theory, Set<String> status) =>
      _axesOf(theory, f).isNotEmpty &&
      f.requiresStatus.every(status.contains) &&
      !f.forbidsStatus.any(status.contains);

  /// 틀의 선택지 태그가 닿는 이론 축 번호.
  static Set<int> _axesOf(Theory theory, StoryFrame f) => {
    for (final c in f.choices)
      for (final p in StoryJudge.poles(theory, c))
        for (var i = 0; i < theory.axes.length; i++)
          if (theory.axes[i].contains(p)) i,
  };

  /// 세 선택지 모두가 태그한 이론 축 번호. 어느 답을 골라도 그 축에 표가 생긴다.
  static Set<int> _fullAxesOf(Theory theory, StoryFrame f) => {
    for (var i = 0; i < theory.axes.length; i++)
      if (f.choices.every(
        (c) => StoryJudge.poles(theory, c).any(theory.axes[i].contains),
      ))
        i,
  };

  /// 주도 방식 이론: 같은 순위(안 쓴 틀/최근 여부) 안에서는 모든 선택지가 이 이론의 극을 태그한
  /// 틀을 앞세운다 (코드 방식의 [_fullAxesOf] 우선과 같은 방식). 어느 답을 골라도 판단 근거가
  /// 생겨 표 없는 만남(재회 중립)이 줄어든다.
  static List<StoryFrame> _fullFirst(
    Theory theory,
    List<StoryFrame> ordered,
    int Function(StoryFrame) rank,
  ) {
    bool full(StoryFrame f) =>
        f.choices.every((c) => StoryJudge.poles(theory, c).isNotEmpty);
    int key(StoryFrame f) => rank(f) * 2 + (full(f) ? 0 : 1);
    // List.sort 는 안정 정렬이 아니므로 원래 위치를 함께 비교해 무작위 순서를 지킨다.
    final indexed = ordered.indexed.toList()
      ..sort((a, b) {
        final byKey = key(a.$2).compareTo(key(b.$2));
        return byKey != 0 ? byKey : a.$1.compareTo(b.$1);
      });
    return [for (final e in indexed) e.$2];
  }

  /// 코드 방식 이론: 같은 순위(안 쓴 틀/최근 여부) 안에서는 아직 안 닿은 축을 태그한 틀을 앞세워
  /// 한 만남에서 모든 축에 한 번 이상 근거가 생기게 한다. 그 축을 모든 선택지가 태그한 틀을
  /// 먼저 고르고, 없으면 일부 선택지만 태그한 틀을 고른다.
  static List<StoryFrame> _coverAxes(
    Theory theory,
    List<StoryFrame> ordered,
    int Function(StoryFrame) rank,
    int count,
  ) {
    final remaining = [...ordered];
    final uncovered = {for (var i = 0; i < theory.axes.length; i++) i};
    final out = <StoryFrame>[];
    while (out.length < count && remaining.isNotEmpty) {
      final best = rank(remaining.first);
      final group = remaining.takeWhile((f) => rank(f) == best);
      final pick =
          group
              .where((f) => _fullAxesOf(theory, f).any(uncovered.contains))
              .firstOrNull ??
          group
              .where((f) => _axesOf(theory, f).any(uncovered.contains))
              .firstOrNull ??
          remaining.first;
      remaining.remove(pick);
      uncovered.removeAll(_axesOf(theory, pick));
      out.add(pick);
    }
    return out;
  }

  static String? _recall(StoryFrame f, List<StoryAnswer> answers) =>
      answers.where((a) => a.frameId == f.id).lastOrNull?.choiceId;

  /// 축별 변주 값. 인물에게 장소 목록이 있으면 `where` 는 그 장소만 쓴다.
  static Map<String, List<String>> _values(
    StoryWorld world,
    StoryCharacter character,
  ) => {
    ...world.variants,
    if (character.places.isNotEmpty) 'where': character.places,
  };

  /// 안 쓴 조합 중 이번 만남 값([meeting])과 가장 많이 겹치는 것을 무작위로, 안 쓴 조합이
  /// 없으면 가장 오래전에 쓴 조합을 고른다.
  static Map<String, String> _variantFor(
    Map<String, List<String>> values,
    StoryFrame f,
    List<StoryAnswer> answers,
    Map<String, String> meeting,
    Random random,
  ) {
    final combos = _combos(values, f.axes);
    final mine = answers.where((a) => a.frameId == f.id).toList();
    final used = {for (final a in mine) a.comboKey};
    final fresh = combos.where((c) => !used.contains(_key(f, c))).toList();
    if (fresh.isNotEmpty) {
      int overlap(Map<String, String> c) =>
          c.entries.where((e) => meeting[e.key] == e.value).length;
      final best = fresh.map(overlap).reduce(max);
      final top = fresh.where((c) => overlap(c) == best).toList();
      return top[random.nextInt(top.length)];
    }

    // 마지막으로 쓴 위치가 가장 앞선 조합.
    final lastUse = <String, int>{};
    for (var i = 0; i < mine.length; i++) {
      lastUse[mine[i].comboKey] = i;
    }
    final oldest = mine
        .map((a) => a.comboKey)
        .toSet()
        .reduce((a, b) => lastUse[a]! <= lastUse[b]! ? a : b);
    return mine.firstWhere((a) => a.comboKey == oldest).variant;
  }

  static String _key(StoryFrame f, Map<String, String> variant) =>
      StoryAnswer(frameId: f.id, variant: variant, choiceId: '').comboKey;

  static List<Map<String, String>> _combos(
    Map<String, List<String>> values,
    List<String> axes,
  ) {
    var out = <Map<String, String>>[{}];
    for (final axis in axes) {
      out = [
        for (final base in out)
          for (final v in values[axis] ?? const <String>[]) {...base, axis: v},
      ];
    }
    return out;
  }
}
