import '../../domain/story/story_record.dart';
import '../../domain/story/story_world.dart';

/// 이야기 만남 기록 <-> 저장 JSON. 시각은 UTC ISO8601.
abstract final class StoryRecordMapper {
  static const schemaVersion = 1;

  static Map<String, dynamic> toJson(List<StoryMeeting> meetings) => {
    'schema': schemaVersion,
    'meetings': [for (final m in meetings) _meetingToJson(m)],
  };

  /// 파일이 없으면(null) 빈 목록. 형식이 깨졌으면 [FormatException] 또는 [TypeError].
  static List<StoryMeeting> fromJson(Map<String, dynamic>? json) {
    if (json == null) return const [];
    return [
      for (final m in json['meetings'] as List)
        _meetingFromJson(m as Map<String, dynamic>),
    ];
  }

  static Map<String, dynamic> _meetingToJson(StoryMeeting m) => {
    'n': m.number,
    'ch': m.characterId,
    'rel': m.relationship.name,
    'at': m.at.toUtc().toIso8601String(),
    if (m.eventId case final String id) 'ev': id,
    'out': m.outcome,
    'ans': [
      for (final a in m.answers)
        {'f': a.frameId, 'v': a.variant, 'c': a.choiceId},
    ],
  };

  static StoryMeeting _meetingFromJson(Map<String, dynamic> j) => StoryMeeting(
    number: j['n'] as int,
    characterId: j['ch'] as String,
    relationship: _relationship(j['rel'] as String),
    at: DateTime.parse(j['at'] as String),
    eventId: j['ev'] as String?,
    outcome: j['out'] as String,
    answers: [
      for (final a in j['ans'] as List)
        StoryAnswer(
          frameId: (a as Map<String, dynamic>)['f'] as String,
          variant: Map<String, String>.from(a['v'] as Map),
          choiceId: a['c'] as String,
        ),
    ],
  );

  static Relationship _relationship(String name) =>
      Relationship.values.firstWhere(
        (r) => r.name == name,
        orElse: () => throw FormatException('알 수 없는 관계: $name'),
      );
}
