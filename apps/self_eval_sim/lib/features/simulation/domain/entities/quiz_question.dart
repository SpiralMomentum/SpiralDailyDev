import 'package:equatable/equatable.dart';

/// 화면이 키 없이 그대로 그리는 풀린 선택지.
final class QuizChoice extends Equatable {
  const QuizChoice({required this.id, required this.text});

  final String id;
  final String text;

  @override
  List<Object?> get props => [id, text];
}

/// 화면이 키 없이 그대로 그리는 풀린 문항.
final class QuizQuestion extends Equatable {
  const QuizQuestion({
    required this.id,
    required this.text,
    required this.choices,
  });

  final String id;
  final String text;
  final List<QuizChoice> choices;

  @override
  List<Object?> get props => [id, text, choices];
}
