import '../entities/accumulation.dart';
import '../entities/catalog.dart';

/// 답변에서 평가 유형을 정한다. 가장 많이 고른 유형이 이기고,
/// 동률이면 동률 유형 중 가장 마지막에 고른 유형을 쓴다.
abstract final class ArchetypeResolver {
  static int resolve(Channel channel, List<Answer> answers) {
    final picked = [
      for (final a in answers)
        if (_archetypeOf(channel, a) case final int archetype) archetype,
    ];
    if (picked.isEmpty) return 0;
    final counts = <int, int>{};
    for (final p in picked) {
      counts[p] = (counts[p] ?? 0) + 1;
    }
    final best = counts.values.reduce((a, b) => a > b ? a : b);
    return picked.lastWhere((p) => counts[p] == best);
  }

  static int? _archetypeOf(Channel channel, Answer answer) {
    final question = channel.questionById(answer.questionId);
    if (question == null) return null;
    for (final c in question.choices) {
      if (c.id == answer.choiceId) return c.archetype;
    }
    return null;
  }
}
