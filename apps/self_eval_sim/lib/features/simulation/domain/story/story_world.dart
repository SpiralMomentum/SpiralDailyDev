import 'package:equatable/equatable.dart';

import '../entities/catalog.dart';

/// 주인공과 인물의 관계 종류. 화면에는 절대 드러내지 않는다.
enum Relationship { friend, lover, enemy, rival }

/// 이야기 속 인물. 인물마다 자기 이론으로 주인공을 판단한다.
/// [unlockAt] 은 전체 만남 수 하한, [requires] 는 인물 id -> 최소 만남 수.
final class StoryCharacter extends Equatable {
  const StoryCharacter({
    required this.id,
    required this.theoryId,
    required this.unlockAt,
    this.requires = const {},
    this.places = const [],
  });

  final String id;
  final String theoryId;
  final int unlockAt;
  final Map<String, int> requires;

  /// 이 인물을 만날 때 질문에 쓰는 `where` 변주 값. 비면 세계의 모든 장소를 쓴다.
  final List<String> places;

  @override
  List<Object?> get props => [id, theoryId, unlockAt, requires, places];
}

/// 틀의 선택지. [traits] 의 키는 이론 id(태그 원천)다.
final class FrameChoice extends Equatable {
  const FrameChoice({required this.id, required this.traits});

  final String id;
  final Map<String, List<String>> traits;

  @override
  List<Object?> get props => [id, traits];
}

/// 질문 틀. [axes] 는 이 틀이 쓰는 변주 축 이름이다 (예: who, where).
final class StoryFrame extends Equatable {
  const StoryFrame({
    required this.id,
    required this.choices,
    required this.axes,
    this.requiresStatus = const {},
    this.forbidsStatus = const {},
  });

  final String id;
  final List<FrameChoice> choices;
  final List<String> axes;
  final Set<String> requiresStatus;
  final Set<String> forbidsStatus;

  @override
  List<Object?> get props => [id, choices, axes, requiresStatus, forbidsStatus];
}

/// 조건을 채우고 아직 안 일어났으면 [characterId] 가 등장하는 만남에서 일어나는 사건.
/// [reveals] 는 새로 생기는 안면 관계다.
final class StoryEvent extends Equatable {
  const StoryEvent({
    required this.id,
    required this.characterId,
    this.minMeetings = 0,
    this.met = const {},
    this.requiresStatus = const {},
    this.grantsStatus,
    this.reveals = const [],
  });

  final String id;
  final String characterId;
  final int minMeetings;
  final Map<String, int> met;
  final Set<String> requiresStatus;
  final String? grantsStatus;
  final List<(String, String)> reveals;

  @override
  List<Object?> get props => [
    id,
    characterId,
    minMeetings,
    met,
    requiresStatus,
    grantsStatus,
    reveals,
  ];
}

/// 이야기 세계 전체. 불변이다.
final class StoryWorld extends Equatable {
  const StoryWorld({
    required this.id,
    required this.characters,
    required this.theories,
    required this.frames,
    required this.variants,
    required this.events,
    required this.links,
  });

  final String id;
  final List<StoryCharacter> characters;
  final List<Theory> theories;
  final List<StoryFrame> frames;

  /// 변주 축 이름 -> 변주 id 목록.
  final Map<String, List<String>> variants;
  final List<StoryEvent> events;

  /// 처음부터 아는 사이인 인물 쌍.
  final List<(String, String)> links;

  StoryCharacter? characterById(String id) =>
      characters.where((c) => c.id == id).firstOrNull;

  Theory? theoryById(String id) =>
      theories.where((t) => t.id == id).firstOrNull;

  StoryFrame? frameById(String id) =>
      frames.where((f) => f.id == id).firstOrNull;

  @override
  List<Object?> get props => [
    id,
    characters,
    theories,
    frames,
    variants,
    events,
    links,
  ];
}
