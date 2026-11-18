import 'package:equatable/equatable.dart';

import 'text_book.dart';

/// 선택지 하나. [archetype] 은 이 선택이 가리키는 채널 내 평가 유형 번호다.
final class Choice extends Equatable {
  const Choice({required this.id, required this.archetype});

  final String id;
  final int archetype;

  @override
  List<Object?> get props => [id, archetype];
}

final class Question extends Equatable {
  const Question({required this.id, required this.choices});

  final String id;
  final List<Choice> choices;

  @override
  List<Object?> get props => [id, choices];
}

/// 자기평가 채널. 문구는 언어 독립 키로만 참조하고 실제 문장은 [TextBook] 이 가진다.
final class Channel extends Equatable {
  const Channel({
    required this.id,
    required this.art,
    required this.archetypeCount,
    required this.questions,
  });

  final String id;
  final String art;
  final int archetypeCount;
  final List<Question> questions;

  Question? questionById(String questionId) {
    for (final q in questions) {
      if (q.id == questionId) return q;
    }
    return null;
  }

  @override
  List<Object?> get props => [id, art, archetypeCount, questions];
}

final class ContentCatalog extends Equatable {
  const ContentCatalog({
    required this.channels,
    required this.questionsPerAttempt,
  });

  final List<Channel> channels;
  final int questionsPerAttempt;

  Channel? channelById(String channelId) {
    for (final c in channels) {
      if (c.id == channelId) return c;
    }
    return null;
  }

  @override
  List<Object?> get props => [channels, questionsPerAttempt];
}

/// 현재 언어로 풀린 콘텐츠 묶음.
final class LocalizedContent extends Equatable {
  const LocalizedContent({required this.catalog, required this.text});

  final ContentCatalog catalog;
  final TextBook text;

  @override
  List<Object?> get props => [catalog, text];
}
