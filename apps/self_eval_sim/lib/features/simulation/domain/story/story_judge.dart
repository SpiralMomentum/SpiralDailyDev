import 'package:equatable/equatable.dart';

import '../entities/catalog.dart';
import 'story_world.dart';

/// 이야기 모드 수치 규칙. 시뮬레이션으로 조정하므로 한 곳에 둔다.
abstract final class StoryRules {
  /// 소문(직접 겪지 않은 일)으로 들은 답의 가중치.
  static const double rumorWeight = 0.5;

  /// 판단이 바뀌려면 새 유형이 이전 유형보다 이만큼 앞서야 한다.
  static const double switchMargin = 2.0;

  /// 같은 상황 틀이 다시 나오기까지 필요한 만남 간격.
  static const int frameGap = 2;

  /// 한 만남의 질문 수.
  static const int questionsPerMeeting = 4;
}

/// 한 답이 드러낸 극들과 그 가중치.
typedef WeightedVote = ({List<String> poles, double weight});

/// 판단 흐름.
/// - [first]: 이 인물의 첫 판단.
/// - [confirmed] / [surprised]: 다시 만나 이번 답이 판단과 같은 쪽 / 반대쪽.
/// - [neutral]: 다시 만났지만 이번 답이 판단 축에 표를 하나도 내지 않아 같은지 다른지 말할 근거가
///   없다. '역시'/'의외' 접두와 맥락을 쓰지 않는다.
enum JudgmentTone { first, confirmed, surprised, neutral }

final class Judgment extends Equatable {
  const Judgment({
    required this.outcome,
    required this.tone,
    required this.tally,
  });

  final String outcome;
  final JudgmentTone tone;
  final Map<String, double> tally;

  @override
  List<Object?> get props => [outcome, tone, tally];
}

/// 인물이 자기 이론으로 주인공을 누적 판단하는 순수 함수 모음.
abstract final class StoryJudge {
  /// 선택지 태그를 이론의 극으로 읽는다. 별칭 없는 극은 그대로.
  /// 이론 축에 없는 극은 뺀다: 다른 이론의 태그를 빌려 읽으면(4체질이 빅파이브 C 태그를 읽는 등)
  /// 이 이론이 재지 않는 극이 남고, 그 극에는 이름 문장이 없어 프롬프트에 키가 그대로 들어간다.
  static List<String> poles(Theory theory, FrameChoice choice) => [
    for (final p in choice.traits[theory.tagSource] ?? const <String>[])
      if (theory.poleAlias[p] ?? p case final pole
          when theory.axes.any((a) => a.contains(pole)))
        pole,
  ];

  /// 가중 표로 유형을 계산한다. 규칙은 PersonalityScorer 와 같고 횟수 대신 가중치를 쓴다.
  static ({String outcome, Map<String, double> tally}) score(
    Theory theory,
    List<WeightedVote> votes,
  ) {
    final raw = _raw(theory, _tally(votes), _order(votes));
    return (outcome: theory.outcomeAlias[raw] ?? raw, tally: _tally(votes));
  }

  static Judgment judge(
    Theory theory, {
    required List<WeightedVote> history,
    required List<WeightedVote> current,
    String? previous,
    double switchMargin = StoryRules.switchMargin,
  }) {
    final all = [...history, ...current];
    final tally = _tally(all);
    // 이 이론이 낼 수 없는 이전 판단(이론이 바뀐 기록 등)은 없는 것으로 본다.
    final unaliased = previous == null ? null : _unalias(theory, previous);
    final previousRaw = unaliased != null && _isOutcome(theory, unaliased)
        ? unaliased
        : null;
    final candidate = _raw(
      theory,
      tally,
      _order(all),
      previous: previousRaw == null ? null : _split(theory, previousRaw),
    );

    final String finalRaw;
    final JudgmentTone tone;
    if (previousRaw == null) {
      finalRaw = candidate;
      tone = JudgmentTone.first;
    } else {
      finalRaw = _hold(theory, tally, candidate, previousRaw, switchMargin);
      tone = !_touches(theory, current, finalRaw)
          ? JudgmentTone.neutral
          : _agrees(theory, current, finalRaw)
          ? JudgmentTone.confirmed
          : JudgmentTone.surprised;
    }
    return Judgment(
      outcome: theory.outcomeAlias[finalRaw] ?? finalRaw,
      tone: tone,
      tally: Map.unmodifiable(tally),
    );
  }

  /// 별칭 전 값이 이 이론의 결과인지. 주도 방식은 축의 극, 코드 방식은 축마다 극 하나.
  static bool _isOutcome(Theory theory, String raw) => switch (theory.mode) {
    TheoryMode.dominant => theory.axes.any((a) => a.contains(raw)),
    TheoryMode.code => _split(theory, raw) != null,
  };

  /// 이번 답이 판단 축에 표를 하나라도 냈는지.
  /// 양극 축 주도 방식은 판단 극의 축, 단극 범주와 코드 방식은 이론 전체를 본다
  /// (단극 범주는 다른 범주의 표도 판단과 비교할 근거가 된다).
  static bool _touches(
    Theory theory,
    List<WeightedVote> current,
    String finalRaw,
  ) {
    final tally = _tally(current);
    if (theory.mode == TheoryMode.dominant) {
      final axis = theory.axes.where((a) => a.contains(finalRaw)).firstOrNull;
      if (axis != null && axis.length > 1) {
        return axis.any((p) => _n(tally, p) > 0);
      }
    }
    return tally.values.any((n) => n > 0);
  }

  /// 이번 답이 최종 판단과 같은 쪽인지 (설계 7절: 반대쪽이면 의외).
  /// - 양극 축(코드 방식의 각 글자, 빅파이브 같은 주도 방식의 판단 극): 이번 답에서 그 축의
  ///   반대 극이 판단 극보다 많을 때만 반대쪽이다. 이번 답이 건드리지 않은 축은 보지 않는다.
  /// - 단극 범주(홀랜드, 갈등 방식 등): 이번 답에 표가 있는데 판단한 범주가 한 번도 없을 때만 반대쪽이다.
  static bool _agrees(
    Theory theory,
    List<WeightedVote> current,
    String finalRaw,
  ) {
    final tally = _tally(current);
    final poles = switch (theory.mode) {
      TheoryMode.dominant => [finalRaw],
      TheoryMode.code => _split(theory, finalRaw) ?? const <String>[],
    };
    return poles.every((p) {
      final axis = theory.axes.where((a) => a.contains(p)).firstOrNull;
      if (axis == null) return true;
      if (axis.length > 1) return _net(tally, theory.axes, p) >= 0;
      return tally.isEmpty || _n(tally, p) > 0;
    });
  }

  static List<String> _order(List<WeightedVote> votes) => [
    for (final v in votes) ...v.poles,
  ];

  static Map<String, double> _tally(List<WeightedVote> votes) {
    final t = <String, double>{};
    for (final v in votes) {
      for (final p in v.poles) {
        t[p] = (t[p] ?? 0) + v.weight;
      }
    }
    return t;
  }

  static double _n(Map<String, double> tally, String pole) => tally[pole] ?? 0;

  static double _net(
    Map<String, double> tally,
    List<List<String>> axes,
    String pole,
  ) {
    final axis = axes.where((a) => a.contains(pole)).firstOrNull;
    if (axis == null) return 0;
    return _n(tally, pole) -
        axis.where((p) => p != pole).fold(0.0, (s, p) => s + _n(tally, p));
  }

  /// 별칭 전 유형 코드(또는 극). [previous] 는 코드 방식에서 이전 판단의 축별 극이다.
  static String _raw(
    Theory theory,
    Map<String, double> tally,
    List<String> order, {
    List<String>? previous,
  }) => switch (theory.mode) {
    TheoryMode.dominant => _dominant(theory, tally, order),
    TheoryMode.code => _code(theory, tally, order, previous: previous),
  };

  static String _unalias(Theory theory, String outcome) {
    for (final e in theory.outcomeAlias.entries) {
      if (e.value == outcome) return e.key;
    }
    return outcome;
  }

  static String _dominant(
    Theory theory,
    Map<String, double> tally,
    List<String> order,
  ) {
    if (order.isEmpty) return theory.axes.first.first;
    final nets = {
      for (final axis in theory.axes)
        for (final p in axis) p: _net(tally, theory.axes, p),
    };
    final best = nets.values.reduce((a, b) => a > b ? a : b);
    final top = {
      for (final e in nets.entries)
        if (e.value == best) e.key,
    };
    return order.firstWhere(top.contains, orElse: () => top.first);
  }

  /// 축마다 표가 많은 극. 동점이거나 표가 없으면 이전 판단의 극, 이전 판단이 없으면
  /// 나중에 드러난 극, 표도 없으면 첫 극. (첫 극 기본값이 결과를 한쪽으로 쏠리게 하지 않도록
  /// 이전 판단을 먼저 따른다.)
  static String _code(
    Theory theory,
    Map<String, double> tally,
    List<String> order, {
    List<String>? previous,
  }) => [
    for (final (i, axis) in theory.axes.indexed)
      () {
        final a = _n(tally, axis.first);
        final b = _n(tally, axis.last);
        if (a != b) return a > b ? axis.first : axis.last;
        if (previous != null) return previous[i];
        final last = order.lastWhere(axis.contains, orElse: () => '');
        return last.isNotEmpty ? last : axis.first;
      }(),
  ].join();

  /// 이력 현상. [previous] 는 별칭 전 값이다.
  static String _hold(
    Theory theory,
    Map<String, double> tally,
    String candidate,
    String previous,
    double margin,
  ) {
    switch (theory.mode) {
      case TheoryMode.dominant:
        if (candidate == previous) return previous;
        final gap =
            _net(tally, theory.axes, candidate) -
            _net(tally, theory.axes, previous);
        return gap >= margin ? candidate : previous;
      case TheoryMode.code:
        final prev = _split(theory, previous);
        final cand = _split(theory, candidate);
        if (prev == null || cand == null) return candidate;
        return [
          for (var i = 0; i < prev.length; i++)
            prev[i] == cand[i] ||
                    _n(tally, cand[i]) - _n(tally, prev[i]) >= margin
                ? cand[i]
                : prev[i],
        ].join();
    }
  }

  /// 코드를 축별 극으로 나눈다. 해석할 수 없으면 null.
  static List<String>? _split(Theory theory, String code) {
    var rest = code;
    final out = <String>[];
    for (final axis in theory.axes) {
      final hit = axis.where(rest.startsWith).toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      if (hit.isEmpty) return null;
      out.add(hit.first);
      rest = rest.substring(hit.first.length);
    }
    return rest.isEmpty ? out : null;
  }
}
