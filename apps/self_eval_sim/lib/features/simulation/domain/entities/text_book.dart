import 'package:equatable/equatable.dart';

import 'evaluation.dart';

/// 한 언어의 콘텐츠 문장 모음. 키 규칙은 doc 의 콘텐츠 키 표를 따른다.
final class TextBook extends Equatable {
  const TextBook({required this.languageCode, required this.entries});

  final String languageCode;
  final Map<String, String> entries;

  /// 누락된 키는 키 자체를 돌려준다. 화면에 키가 보이면 콘텐츠 누락이다.
  String of(String key) => entries[key] ?? key;

  String channelName(String channelId) => of('$channelId.name');
  String tagline(String channelId) => of('$channelId.tagline');
  String speaker(String channelId) => of('$channelId.speaker');
  String place(String channelId) => of('$channelId.place');
  String question(String channelId, String questionId) =>
      of('$channelId.$questionId');
  String choice(String channelId, String questionId, String choiceId) =>
      of('$channelId.$questionId.$choiceId');
  String archetypeTitle(String channelId, int archetype) =>
      of('$channelId.a$archetype.title');
  List<String> archetypeLines(String channelId, int archetype) => [
    of('$channelId.a$archetype.line1'),
    of('$channelId.a$archetype.line2'),
  ];
  String extensionPlace(String channelId) => of('$channelId.ext.place');
  /// 결과를 맺는 채널 분위기의 명언풍 한 줄. 결과 유형마다 2개.
  static const sayingsPerArchetype = 2;
  String saying(String channelId, int archetype, int n) =>
      of('$channelId.a$archetype.saying${n % sayingsPerArchetype + 1}');

  /// 결과 유형을 밝히는 첫 줄. `{title}` 자리에 결과 이름이 들어간다.
  String reveal(String channelId, String title) =>
      of('$channelId.reveal').replaceAll('{title}', title);
  String theoryName(String theoryId) => of('theory.$theoryId.name');

  /// 극 또는 유형 하나의 이름. 16유형은 글자(E, I ...)와 네 글자 유형 모두 이 키를 쓴다.
  String poleLabel(String theoryId, String pole) =>
      of('theory.$theoryId.$pole.label');

  TypeProfile typeProfile(String theoryId, String outcome) => TypeProfile(
    theoryName: theoryName(theoryId),
    label: poleLabel(theoryId, outcome),
    description: of('theory.$theoryId.$outcome.desc'),
    strength: of('theory.$theoryId.$outcome.strength'),
    weakness: of('theory.$theoryId.$outcome.weakness'),
  );
  List<String> extensionLines(String channelId) => [
    of('$channelId.ext1'),
    of('$channelId.ext2'),
  ];

  @override
  List<Object?> get props => [languageCode, entries];
}
