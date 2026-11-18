import 'package:equatable/equatable.dart';

import '../../domain/entities/accumulation.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/evaluation.dart';

enum AttemptPhase { quiz, generating, result, failure }

/// 대기 중 보상형 광고 진행 상태.
enum AdStatus { none, offered, watching, rewarded, declined, failed }

final class AttemptState extends Equatable {
  const AttemptState({
    this.phase = AttemptPhase.quiz,
    this.questions = const [],
    this.answers = const [],
    this.adStatus = AdStatus.none,
    this.result,
    this.errorMessage,
  });

  final AttemptPhase phase;
  final List<Question> questions;
  final List<Answer> answers;
  final AdStatus adStatus;
  final EvaluationResult? result;
  final String? errorMessage;

  Question? get currentQuestion =>
      answers.length < questions.length ? questions[answers.length] : null;

  AttemptState copyWith({
    AttemptPhase? phase,
    List<Question>? questions,
    List<Answer>? answers,
    AdStatus? adStatus,
    EvaluationResult? result,
    String? errorMessage,
  }) =>
      AttemptState(
        phase: phase ?? this.phase,
        questions: questions ?? this.questions,
        answers: answers ?? this.answers,
        adStatus: adStatus ?? this.adStatus,
        result: result ?? this.result,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [phase, questions, answers, adStatus, result, errorMessage];
}
