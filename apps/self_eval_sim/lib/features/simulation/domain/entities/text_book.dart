import 'package:equatable/equatable.dart';

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
  List<String> extensionLines(String channelId) =>
      [of('$channelId.ext1'), of('$channelId.ext2')];

  @override
  List<Object?> get props => [languageCode, entries];
}
