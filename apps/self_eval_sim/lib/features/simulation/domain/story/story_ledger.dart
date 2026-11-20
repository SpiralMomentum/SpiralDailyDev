import 'package:equatable/equatable.dart';

import 'story_record.dart';
import 'story_world.dart';

/// 세계와 만남 기록에서 한 번 계산한 파생 상태. 불변이며 IO 가 없다.
final class StoryLedger extends Equatable {
  const StoryLedger._({
    required this.total,
    required this.status,
    required this.firedEvents,
    required this.links,
    required this.meetings,
  });

  factory StoryLedger.of(StoryWorld world, List<StoryMeeting> meetings) {
    final ordered = [...meetings]..sort((a, b) => a.number.compareTo(b.number));
    final fired = {
      for (final m in ordered)
        if (m.eventId != null) m.eventId!,
    };
    final events = world.events.where((e) => fired.contains(e.id)).toList();
    return StoryLedger._(
      total: ordered.length,
      status: Set.unmodifiable({
        for (final e in events)
          if (e.grantsStatus != null) e.grantsStatus!,
      }),
      firedEvents: Set.unmodifiable(fired),
      links: Set.unmodifiable({
        for (final l in world.links) l,
        for (final e in events)
          for (final r in e.reveals) r,
      }),
      meetings: List.unmodifiable(ordered),
    );
  }

  /// 만남 수.
  final int total;

  /// 일어난 사건이 준 상태.
  final Set<String> status;
  final Set<String> firedEvents;

  /// 기본 연결과 공개된 연결. 쌍은 정의된 방향 그대로이며 비교는 acquainted 로 순서 무관하게 한다.
  final Set<(String, String)> links;

  final List<StoryMeeting> meetings;

  Iterable<StoryMeeting> _with(String id) =>
      meetings.where((m) => m.characterId == id);

  int metCount(String characterId) => _with(characterId).length;

  Relationship? relationship(String characterId) =>
      _with(characterId).firstOrNull?.relationship;

  String? lastOutcome(String characterId) =>
      _with(characterId).lastOrNull?.outcome;

  int? lastMetAt(String characterId) => _with(characterId).lastOrNull?.number;

  bool acquainted(String a, String b) =>
      links.contains((a, b)) || links.contains((b, a));

  /// 만난 적 있는 아는 인물.
  List<String> acquaintancesOf(String characterId) {
    final out = <String>[];
    for (final l in links) {
      final other = l.$1 == characterId
          ? l.$2
          : l.$2 == characterId
          ? l.$1
          : null;
      if (other != null && other != characterId && metCount(other) > 0) {
        out.add(other);
      }
    }
    return out;
  }

  /// 그 인물에게 한 답. 시간 순.
  List<StoryAnswer> answersTo(String characterId) => [
    for (final m in _with(characterId)) ...m.answers,
  ];

  /// 아는 인물에게 한 답. 시간 순.
  List<StoryAnswer> rumorsAbout(String characterId) {
    final known = acquaintancesOf(characterId).toSet();
    return [
      for (final m in meetings)
        if (known.contains(m.characterId)) ...m.answers,
    ];
  }

  /// 최근 [gap] 만남에 나온 틀 id. 시간 순.
  List<String> recentFrames(int gap) {
    final recent = gap <= 0
        ? const <StoryMeeting>[]
        : meetings.skip(meetings.length > gap ? meetings.length - gap : 0);
    return [
      for (final m in recent)
        for (final a in m.answers) a.frameId,
    ];
  }

  @override
  List<Object?> get props => [total, status, firedEvents, links, meetings];
}
