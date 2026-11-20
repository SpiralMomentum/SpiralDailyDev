import 'package:equatable/equatable.dart';

import 'story_world.dart';

/// 한 질문에 대한 답. [variant] 는 축 이름 -> 변주 id.
final class StoryAnswer extends Equatable {
  const StoryAnswer({
    required this.frameId,
    required this.variant,
    required this.choiceId,
  });

  final String frameId;
  final Map<String, String> variant;
  final String choiceId;

  /// 틀 id 와 축 이름순 변주 id 를 `|` 로 이은 키.
  String get comboKey {
    final axes = variant.keys.toList()..sort();
    return [frameId, for (final a in axes) variant[a]!].join('|');
  }

  @override
  List<Object?> get props => [frameId, variant, choiceId];
}

/// 만남 한 번의 기록. [number] 는 1부터.
final class StoryMeeting extends Equatable {
  const StoryMeeting({
    required this.number,
    required this.characterId,
    required this.relationship,
    required this.answers,
    required this.outcome,
    required this.at,
    this.eventId,
  });

  final int number;
  final String characterId;
  final Relationship relationship;
  final List<StoryAnswer> answers;
  final String outcome;
  final DateTime at;
  final String? eventId;

  @override
  List<Object?> get props => [
    number,
    characterId,
    relationship,
    answers,
    outcome,
    at,
    eventId,
  ];
}
