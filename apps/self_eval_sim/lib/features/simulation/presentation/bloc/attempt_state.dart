import 'package:equatable/equatable.dart';

import '../../domain/entities/evaluation.dart';
import '../../domain/entities/quiz_question.dart';

enum AttemptPhase { quiz, generating, result, failure }

/// 대기 중 보상형 광고 진행 상태.
enum AdStatus { none, offered, watching, rewarded, declined, failed }

/// [questions] 는 화면이 그대로 그리는 풀린 문항, [answers] 는 고른 선택지 id,
/// [intro] 는 첫 질문 위에 보일 도입 문장, [art] 는 문항/대기 화면 배경 키.
final class AttemptState extends Equatable {
  const AttemptState({
    this.phase = AttemptPhase.quiz,
    this.art = '',
    this.intro = const [],
    this.questions = const [],
    this.answers = const [],
    this.adStatus = AdStatus.none,
    this.result,
    this.errorMessage,
  });

  final AttemptPhase phase;
  final String art;
  final List<String> intro;
  final List<QuizQuestion> questions;
  final List<String> answers;
  final AdStatus adStatus;
  final EvaluationResult? result;
  final String? errorMessage;

  QuizQuestion? get currentQuestion =>
      answers.length < questions.length ? questions[answers.length] : null;

  AttemptState copyWith({
    AttemptPhase? phase,
    String? art,
    List<String>? intro,
    List<QuizQuestion>? questions,
    List<String>? answers,
    AdStatus? adStatus,
    EvaluationResult? result,
    String? errorMessage,
  }) => AttemptState(
    phase: phase ?? this.phase,
    art: art ?? this.art,
    intro: intro ?? this.intro,
    questions: questions ?? this.questions,
    answers: answers ?? this.answers,
    adStatus: adStatus ?? this.adStatus,
    result: result ?? this.result,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [
    phase,
    art,
    intro,
    questions,
    answers,
    adStatus,
    result,
    errorMessage,
  ];
}
