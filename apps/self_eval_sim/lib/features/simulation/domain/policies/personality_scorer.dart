import 'dart:math';

import 'package:equatable/equatable.dart';

import '../entities/accumulation.dart';
import '../entities/catalog.dart';

/// 한 성격 이론으로 읽은 결과. [outcome] 은 유형 키(예: `C+`, `INTJ`, `5`)이고
/// [tally] 는 극별로 몇 번 드러났는지, [answers] 는 계산에 쓴 답 수다.
final class TraitReading extends Equatable {
  const TraitReading({
    required this.theoryId,
    required this.outcome,
    required this.tally,
    required this.answers,
  });

  final String theoryId;
  final String outcome;
  final Map<String, int> tally;
  final int answers;

  @override
  List<Object?> get props => [theoryId, outcome, tally, answers];
}

/// 선택지의 성향 태그로 성격 유형을 계산하는 순수 함수 모음.
/// 같은 답이면 항상 같은 유형이 나온다 (모델은 계산하지 않고 설명만 한다).
abstract final class PersonalityScorer {
  /// 한 답이 [theoryId] 에서 드러내는 극들. 콘텐츠에 없는 답이면 빈 목록.
  static List<String> polesOf(
    ContentCatalog catalog,
    String channelId,
    String questionId,
    String choiceId,
    String theoryId,
  ) =>
      catalog
          .channelById(channelId)
          ?.choiceOf(questionId, choiceId)
          ?.traits[theoryId] ??
      const [];

  /// 시행 기록들의 모든 답을 시간 순으로 모아 [theory] 로 읽는다.
  static TraitReading readAttempts(
    ContentCatalog catalog,
    Theory theory,
    Iterable<AttemptRecord> attempts,
  ) {
    final votes = [
      for (final a in attempts)
        for (final x in a.answers)
          polesOf(catalog, a.channelId, x.questionId, x.choiceId, theory.id),
    ];
    return score(theory, votes);
  }

  /// [votes] 는 답마다 드러난 극 목록이며 답한 순서대로다.
  static TraitReading score(Theory theory, List<List<String>> votes) {
    final order = <String>[for (final v in votes) ...v];
    final tally = <String, int>{};
    for (final p in order) {
      tally[p] = (tally[p] ?? 0) + 1;
    }
    final outcome = switch (theory.mode) {
      TheoryMode.dominant => _dominant(theory, tally, order),
      TheoryMode.code => _code(theory, tally, order, votes.length),
    };
    return TraitReading(
      theoryId: theory.id,
      outcome: outcome,
      tally: Map.unmodifiable(tally),
      answers: votes.length,
    );
  }

  static int _count(Map<String, int> tally, String pole) => tally[pole] ?? 0;

  /// 극의 순점수 = 그 극 횟수 - 반대 극 횟수. 가장 높은 극이 유형이고,
  /// 동률이면 먼저 드러난 극이 이긴다. 아무 답도 없으면 첫 극.
  static String _dominant(
    Theory theory,
    Map<String, int> tally,
    List<String> order,
  ) {
    int net(List<String> axis, String pole) =>
        _count(tally, pole) -
        axis.where((p) => p != pole).fold(0, (n, p) => n + _count(tally, p));
    final candidates = [
      for (final axis in theory.axes)
        for (final pole in axis) (pole: pole, net: net(axis, pole)),
    ];
    if (order.isEmpty) return theory.axes.first.first;
    final best = candidates.map((c) => c.net).reduce(max);
    final top = {
      for (final c in candidates)
        if (c.net == best) c.pole,
    };
    return order.firstWhere(top.contains, orElse: () => top.first);
  }

  /// 축마다 많이 드러난 극을 고른다. 동률이면 나중에 드러난 극,
  /// 그 축이 한 번도 드러나지 않았으면 답 수의 홀짝으로 정한다.
  static String _code(
    Theory theory,
    Map<String, int> tally,
    List<String> order,
    int answers,
  ) => theory.axes.map((axis) {
    final a = _count(tally, axis.first);
    final b = _count(tally, axis.last);
    if (a != b) return a > b ? axis.first : axis.last;
    final last = order.lastWhere(axis.contains, orElse: () => '');
    return last.isNotEmpty ? last : axis[answers % axis.length];
  }).join();
}

/// 시행마다 쓸 이론을 고르는 정책. 직전 시행과 같은 이론은 피한다.
abstract final class TheoryPicker {
  static Theory? pick(List<Theory> theories, Random random, {String? avoid}) {
    if (theories.isEmpty) return null;
    final pool = theories.where((t) => t.id != avoid).toList();
    final from = pool.isEmpty ? theories : pool;
    return from[random.nextInt(from.length)];
  }
}
