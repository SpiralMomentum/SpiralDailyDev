import 'package:equatable/equatable.dart';

sealed class AttemptEvent extends Equatable {
  const AttemptEvent();
}

/// 새 시행을 시작한다 (첫 진입, 한 번 더).
final class AttemptStarted extends AttemptEvent {
  const AttemptStarted();

  @override
  List<Object?> get props => [];
}

final class ChoiceSelected extends AttemptEvent {
  const ChoiceSelected(this.choiceId);

  final String choiceId;

  @override
  List<Object?> get props => [choiceId];
}

final class AdWatchRequested extends AttemptEvent {
  const AdWatchRequested();

  @override
  List<Object?> get props => [];
}

final class AdSkipped extends AttemptEvent {
  const AdSkipped();

  @override
  List<Object?> get props => [];
}
