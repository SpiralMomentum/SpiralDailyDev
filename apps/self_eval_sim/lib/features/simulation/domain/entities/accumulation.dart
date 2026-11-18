import 'package:equatable/equatable.dart';

/// 한 문항에 대한 선택 원본.
final class Answer extends Equatable {
  const Answer({required this.questionId, required this.choiceId});

  final String questionId;
  final String choiceId;

  @override
  List<Object?> get props => [questionId, choiceId];
}

/// 개별 시행 원본 로그. [index] 는 1부터 시작하는 전체 통합 시행 순번이다.
final class AttemptRecord extends Equatable {
  const AttemptRecord({
    required this.index,
    required this.channelId,
    required this.answers,
    required this.archetype,
    required this.at,
  });

  final int index;
  final String channelId;
  final List<Answer> answers;
  final int archetype;
  final DateTime at;

  @override
  List<Object?> get props => [index, channelId, answers, archetype, at];
}

enum MaterialKind { attempt, manifestation }

/// 발현에 쓰인 재료 하나. [sourceIndex] 는 재료가 나온 시행 순번이다.
/// 발현 재료는 과거 발현이 썼던 선택을 다시 가리킨다.
final class MaterialRef extends Equatable {
  const MaterialRef({
    required this.kind,
    required this.sourceIndex,
    required this.channelId,
    required this.questionId,
    required this.choiceId,
  });

  final MaterialKind kind;
  final int sourceIndex;
  final String channelId;
  final String questionId;
  final String choiceId;

  String get choiceKey => '$channelId.$questionId.$choiceId';
  String get signatureToken => '${kind.name}:$sourceIndex:$choiceKey';

  @override
  List<Object?> get props =>
      [kind, sourceIndex, channelId, questionId, choiceId];
}

enum ManifestationForm { mixed, separate }

final class ManifestationRecord extends Equatable {
  const ManifestationRecord({
    required this.attemptIndex,
    required this.form,
    required this.materials,
  });

  final int attemptIndex;
  final ManifestationForm form;
  final List<MaterialRef> materials;

  @override
  List<Object?> get props => [attemptIndex, form, materials];
}

/// 기기 안에 보관되는 누적 상태 전체.
/// [gaugePermille] 는 다음 시행의 발현 확률(천분율, 0~1000)이다.
final class AccumulationState extends Equatable {
  const AccumulationState({
    this.attempts = const [],
    this.manifestations = const [],
    this.gaugePermille = 0,
  });

  static const empty = AccumulationState();

  final List<AttemptRecord> attempts;
  final List<ManifestationRecord> manifestations;
  final int gaugePermille;

  int get nextAttemptIndex => attempts.isEmpty ? 1 : attempts.last.index + 1;

  AccumulationState copyWith({
    List<AttemptRecord>? attempts,
    List<ManifestationRecord>? manifestations,
    int? gaugePermille,
  }) =>
      AccumulationState(
        attempts: attempts ?? this.attempts,
        manifestations: manifestations ?? this.manifestations,
        gaugePermille: gaugePermille ?? this.gaugePermille,
      );

  @override
  List<Object?> get props => [attempts, manifestations, gaugePermille];
}
