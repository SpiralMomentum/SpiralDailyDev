import 'dart:math';

import 'story_ledger.dart';
import 'story_world.dart';

/// 누구를 만나고 어떤 사건이 일어날지 정하는 순수 함수 모음.
abstract final class StoryDirector {
  /// 열린 인물. 세계 정의 순서를 유지한다.
  static List<StoryCharacter> unlocked(
    StoryWorld world,
    StoryLedger ledger,
  ) => [
    for (final c in world.characters)
      if (ledger.total >= c.unlockAt &&
          c.requires.entries.every((r) => ledger.metCount(r.key) >= r.value))
        c,
  ];

  /// 조건을 채웠고 아직 안 일어난 그 인물의 첫 사건.
  static StoryEvent? pendingEvent(
    StoryWorld world,
    StoryLedger ledger,
    String characterId,
  ) => world.events
      .where(
        (e) =>
            e.characterId == characterId &&
            !ledger.firedEvents.contains(e.id) &&
            e.minMeetings <= ledger.total &&
            e.met.entries.every((m) => ledger.metCount(m.key) >= m.value) &&
            ledger.status.containsAll(e.requiresStatus),
      )
      .firstOrNull;

  /// 다음 만날 인물. 사건 -> 미만남 -> 오래 못 본 인물 가중 무작위.
  /// 사건 인물이 직전 만남 인물이면 (다른 열린 인물이 있을 때) 사건을 한 만남 미룬다.
  static StoryCharacter nextCharacter(
    StoryWorld world,
    StoryLedger ledger,
    Random random,
  ) {
    final open = unlocked(world, ledger);
    final previous = ledger.meetings.lastOrNull?.characterId;
    final others = open.where((c) => c.id != previous).toList();
    final withEvent = open
        .where(
          (c) =>
              pendingEvent(world, ledger, c.id) != null &&
              (c.id != previous || others.isEmpty),
        )
        .firstOrNull;
    if (withEvent != null) return withEvent;
    final unmet = open.where((c) => ledger.metCount(c.id) == 0).firstOrNull;
    if (unmet != null) return unmet;

    final pool = others.isEmpty ? open : others;
    if (pool.length == 1) return pool.first;

    final weights = [
      for (final c in pool)
        max(1, ledger.total - (ledger.lastMetAt(c.id) ?? 0)),
    ];
    var roll = random.nextInt(weights.reduce((a, b) => a + b));
    for (var i = 0; i < pool.length; i++) {
      if (roll < weights[i]) return pool[i];
      roll -= weights[i];
    }
    return pool.last;
  }

  /// 만난 적 있으면 기록된 관계, 없으면 균등 무작위.
  static Relationship relationshipFor(
    StoryLedger ledger,
    String characterId,
    Random random,
  ) =>
      ledger.relationship(characterId) ??
      Relationship.values[random.nextInt(Relationship.values.length)];
}
