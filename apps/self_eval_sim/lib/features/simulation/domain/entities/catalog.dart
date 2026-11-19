import 'package:equatable/equatable.dart';

import 'text_book.dart';

/// 선택지 하나. [archetype] 은 이 선택이 가리키는 채널 내 평가 유형 번호다.
/// [traits] 는 성격 이론 id 별로 이 선택이 드러내는 극(pole) 목록이다.
final class Choice extends Equatable {
  const Choice({
    required this.id,
    required this.archetype,
    this.traits = const {},
  });

  final String id;
  final int archetype;
  final Map<String, List<String>> traits;

  @override
  List<Object?> get props => [id, archetype, traits];
}

/// 결과 유형을 정하는 방식.
/// - dominant: 가장 강한 극 하나가 유형이다 (빅파이브, 에니어그램, 4기질).
/// - code: 축마다 이긴 극을 이어 붙인 것이 유형이다 (16유형).
enum TheoryMode { dominant, code }

/// 성격 이론 하나. [axes] 의 각 축은 서로 반대인 극 1~2개다.
final class Theory extends Equatable {
  const Theory({required this.id, required this.mode, required this.axes});

  final String id;
  final TheoryMode mode;
  final List<List<String>> axes;

  @override
  List<Object?> get props => [id, mode, axes];
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

  Choice? choiceOf(String questionId, String choiceId) {
    for (final c in questionById(questionId)?.choices ?? const <Choice>[]) {
      if (c.id == choiceId) return c;
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
    this.theories = const [],
  });

  final List<Channel> channels;
  final int questionsPerAttempt;

  /// 시행마다 돌아가며 쓰는 성격 이론들.
  final List<Theory> theories;

  Theory? theoryById(String? theoryId) {
    for (final t in theories) {
      if (t.id == theoryId) return t;
    }
    return null;
  }

  Channel? channelById(String channelId) {
    for (final c in channels) {
      if (c.id == channelId) return c;
    }
    return null;
  }

  @override
  List<Object?> get props => [channels, questionsPerAttempt, theories];
}

/// 현재 언어로 풀린 콘텐츠 묶음.
final class LocalizedContent extends Equatable {
  const LocalizedContent({required this.catalog, required this.text});

  final ContentCatalog catalog;
  final TextBook text;

  @override
  List<Object?> get props => [catalog, text];
}
