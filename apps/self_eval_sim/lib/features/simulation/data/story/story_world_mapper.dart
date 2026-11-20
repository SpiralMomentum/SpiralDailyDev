import '../../domain/story/story_world.dart';
import '../mappers/catalog_mapper.dart';

/// world.json 을 [StoryWorld] 로 바꾼다. 형식이 어긋나면 예외가 난다.
abstract final class StoryWorldMapper {
  static StoryWorld fromJson(Map<String, dynamic> json) => StoryWorld(
    id: json['id'] as String,
    characters: [
      for (final c in json['chars'] as List)
        _character(c as Map<String, dynamic>),
    ],
    theories: [
      for (final t in json['theories'] as List)
        CatalogMapper.theory(t as Map<String, dynamic>),
    ],
    frames: [
      for (final f in json['frames'] as List) _frame(f as Map<String, dynamic>),
    ],
    variants: {
      for (final e in (json['variants'] as Map).entries)
        e.key as String: (e.value as List).cast<String>(),
    },
    events: [
      for (final e in (json['events'] as List? ?? const []))
        _event(e as Map<String, dynamic>),
    ],
    links: _pairs(json['links']),
  );

  static StoryCharacter _character(Map<String, dynamic> j) => StoryCharacter(
    id: j['id'] as String,
    theoryId: j['theory'] as String,
    unlockAt: j['unlockAt'] as int,
    requires: _intMap(j['requires']),
    places: ((j['places'] as List?) ?? const []).cast<String>(),
  );

  static StoryFrame _frame(Map<String, dynamic> j) => StoryFrame(
    id: j['id'] as String,
    axes: (j['axes'] as List).cast<String>(),
    requiresStatus: ((j['requiresStatus'] as List?) ?? const [])
        .cast<String>()
        .toSet(),
    forbidsStatus: ((j['forbidsStatus'] as List?) ?? const [])
        .cast<String>()
        .toSet(),
    choices: [
      for (final c in j['choices'] as List)
        FrameChoice(
          id: (c as Map<String, dynamic>)['id'] as String,
          traits: {
            for (final e in ((c['traits'] as Map?) ?? const {}).entries)
              e.key as String: (e.value as List).cast<String>(),
          },
        ),
    ],
  );

  static StoryEvent _event(Map<String, dynamic> j) => StoryEvent(
    id: j['id'] as String,
    characterId: j['char'] as String,
    minMeetings: (j['minMeetings'] as int?) ?? 0,
    met: _intMap(j['met']),
    requiresStatus: ((j['requiresStatus'] as List?) ?? const [])
        .cast<String>()
        .toSet(),
    grantsStatus: j['grants'] as String?,
    reveals: _pairs(j['reveals']),
  );

  static Map<String, int> _intMap(Object? v) => {
    for (final e in ((v as Map?) ?? const {}).entries)
      e.key as String: e.value as int,
  };

  static List<(String, String)> _pairs(Object? v) => [
    for (final p in (v as List?) ?? const [])
      ((p as List)[0] as String, p[1] as String),
  ];
}
