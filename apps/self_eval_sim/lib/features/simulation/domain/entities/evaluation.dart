import 'package:equatable/equatable.dart';

import 'accumulation.dart';

enum SceneKind { base, manifestation, extension }

/// 미연시형 결과 화면의 한 장면. [art] 는 배경 에셋 키다.
final class Scene extends Equatable {
  const Scene({
    required this.kind,
    required this.art,
    required this.place,
    required this.speaker,
    required this.lines,
  });

  final SceneKind kind;
  final String art;
  final String place;
  final String speaker;
  final List<String> lines;

  Scene withLines(List<String> next) => Scene(
        kind: kind,
        art: art,
        place: place,
        speaker: speaker,
        lines: next,
      );

  @override
  List<Object?> get props => [kind, art, place, speaker, lines];
}

final class EvaluationResult extends Equatable {
  const EvaluationResult({
    required this.channelId,
    required this.attemptIndex,
    required this.archetype,
    required this.title,
    required this.scenes,
    this.manifestationForm,
    this.extended = false,
    this.baseSource = NarrationSource.template,
    this.manifestationSource,
  });

  final String channelId;
  final int attemptIndex;
  final int archetype;
  final String title;
  final List<Scene> scenes;

  /// 발현이 없었으면 null.
  final ManifestationForm? manifestationForm;

  /// 보상형 광고로 장면이 확장되었는지.
  final bool extended;

  /// 기본 결과 대사를 만든 쪽.
  final NarrationSource baseSource;

  /// 발현 대사를 만든 쪽. 발현이 없으면 null.
  final NarrationSource? manifestationSource;

  bool get manifested => manifestationForm != null;

  EvaluationResult copyWith({List<Scene>? scenes, bool? extended}) =>
      EvaluationResult(
        channelId: channelId,
        attemptIndex: attemptIndex,
        archetype: archetype,
        title: title,
        scenes: scenes ?? this.scenes,
        manifestationForm: manifestationForm,
        extended: extended ?? this.extended,
        baseSource: baseSource,
        manifestationSource: manifestationSource,
      );

  @override
  List<Object?> get props => [
        channelId,
        attemptIndex,
        archetype,
        title,
        scenes,
        manifestationForm,
        extended,
        baseSource,
        manifestationSource,
      ];
}

/// 답변 직후 빠르게 확정되는 시행 계획. 문장 생성(느린 단계) 전에 발현 여부를 알려
/// 대기 시간 동안 광고 제안 여부를 정할 수 있게 한다.
final class AttemptPlan extends Equatable {
  const AttemptPlan({
    required this.channelId,
    required this.attempt,
    required this.manifestation,
  });

  final String channelId;
  final AttemptRecord attempt;
  final ManifestationRecord? manifestation;

  bool get manifested => manifestation != null;

  @override
  List<Object?> get props => [channelId, attempt, manifestation];
}

/// 발현 문장을 만들기 위해 텍스트로 풀린 재료.
final class ResolvedMaterial extends Equatable {
  const ResolvedMaterial({
    required this.kind,
    required this.ago,
    required this.channelName,
    required this.choiceText,
  });

  final MaterialKind kind;
  final int ago;
  final String channelName;
  final String choiceText;

  @override
  List<Object?> get props => [kind, ago, channelName, choiceText];
}

/// 온디바이스 모델 또는 템플릿 엔진이 만든 발현 문장.
final class ManifestationText extends Equatable {
  const ManifestationText({
    required this.lines,
    required this.separateSpeaker,
    required this.separatePlace,
    this.source = NarrationSource.template,
  });

  final List<String> lines;
  final String separateSpeaker;
  final String separatePlace;
  final NarrationSource source;

  @override
  List<Object?> get props => [lines, separateSpeaker, separatePlace, source];
}

/// 문장을 누가 만들었는지. 시뮬레이션 리포트와 품질 추적에 쓴다.
enum NarrationSource { model, template }

final class Narration extends Equatable {
  const Narration({required this.lines, required this.source});

  final List<String> lines;
  final NarrationSource source;

  @override
  List<Object?> get props => [lines, source];
}

/// 개별 시행 결과 대사 생성 요청 (현재 언어 문장으로 풀린 값).
final class BaseNarrationRequest extends Equatable {
  const BaseNarrationRequest({
    required this.languageCode,
    required this.speaker,
    required this.place,
    required this.title,
    required this.answers,
    required this.examples,
    required this.fallbackLines,
  });

  final String languageCode;
  final String speaker;
  final String place;
  final String title;

  /// (문항, 고른 선택지) 문장 쌍.
  final List<(String, String)> answers;

  /// 화자 말투 예시 (채널의 기본 결과 대사들).
  final List<String> examples;

  /// 모델을 쓸 수 없을 때 보여 줄 콘텐츠 대사.
  final List<String> fallbackLines;

  @override
  List<Object?> get props =>
      [languageCode, speaker, place, title, answers, examples, fallbackLines];
}

/// 누적 발현 대사 생성 요청.
final class ManifestationRequest extends Equatable {
  const ManifestationRequest({
    required this.languageCode,
    required this.form,
    required this.speaker,
    required this.title,
    required this.materials,
    this.examples = const [],
  });

  final String languageCode;
  final ManifestationForm form;
  final String speaker;
  final String title;
  final List<ResolvedMaterial> materials;

  /// 섞임 형태일 때 화자 말투 예시 (별도 장면은 비움).
  final List<String> examples;

  @override
  List<Object?> get props => [languageCode, form, speaker, title, materials, examples];
}
