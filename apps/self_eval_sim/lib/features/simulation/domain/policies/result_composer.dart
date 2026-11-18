import '../entities/accumulation.dart';
import '../entities/catalog.dart';
import '../entities/evaluation.dart';
import '../entities/text_book.dart';

/// 결과 장면을 조립하는 순수 함수 모음.
abstract final class ResultComposer {
  /// [lines] 가 없으면 콘텐츠의 기본 결과 대사를 쓴다.
  static Scene baseScene(
    Channel channel,
    int archetype,
    TextBook text, {
    List<String>? lines,
  }) =>
      Scene(
        kind: SceneKind.base,
        art: channel.art,
        place: text.place(channel.id),
        speaker: text.speaker(channel.id),
        lines: lines ?? text.archetypeLines(channel.id, archetype),
      );

  /// 발현 형태에 따라 장면을 섞는다.
  /// - mixed: 기본 장면 대사 뒤에 발현 대사를 이어 붙인다.
  /// - separate: 기본 장면 뒤에 별도 발현 장면을 붙인다.
  static List<Scene> withManifestation(
    Scene base,
    ManifestationForm form,
    ManifestationText manifest,
  ) =>
      switch (form) {
        ManifestationForm.mixed => [
            base.withLines([...base.lines, ...manifest.lines]),
          ],
        ManifestationForm.separate => [
            base,
            Scene(
              kind: SceneKind.manifestation,
              art: 'manifestation',
              place: manifest.separatePlace,
              speaker: manifest.separateSpeaker,
              lines: manifest.lines,
            ),
          ],
      };

  static EvaluationResult compose({
    required Channel channel,
    required AttemptPlan plan,
    required TextBook text,
    Narration? base,
    ManifestationText? manifest,
  }) {
    final scene = baseScene(channel, plan.attempt.archetype, text, lines: base?.lines);
    final form = plan.manifestation?.form;
    return EvaluationResult(
      channelId: channel.id,
      attemptIndex: plan.attempt.index,
      archetype: plan.attempt.archetype,
      title: text.archetypeTitle(channel.id, plan.attempt.archetype),
      scenes: form != null && manifest != null
          ? withManifestation(scene, form, manifest)
          : [scene],
      manifestationForm: manifest == null ? null : form,
      baseSource: base?.source ?? NarrationSource.template,
      manifestationSource: manifest?.source,
    );
  }

  /// 보상형 광고 보상: 추가 장면과 추가 서술을 덧붙인다.
  static EvaluationResult extend(
    EvaluationResult result,
    Channel channel,
    TextBook text,
  ) {
    if (result.extended) return result;
    final lines = text.extensionLines(channel.id);
    return result.copyWith(
      extended: true,
      scenes: [
        ...result.scenes,
        Scene(
          kind: SceneKind.extension,
          art: '${channel.art}_ext',
          place: text.extensionPlace(channel.id),
          speaker: text.speaker(channel.id),
          lines: lines,
        ),
      ],
    );
  }

  /// 개별 시행 대사 생성 요청을 만든다.
  static BaseNarrationRequest baseRequest(
    Channel channel,
    AttemptRecord attempt,
    TextBook text,
  ) =>
      BaseNarrationRequest(
        languageCode: text.languageCode,
        speaker: text.speaker(channel.id),
        place: text.place(channel.id),
        title: text.archetypeTitle(channel.id, attempt.archetype),
        answers: [
          for (final a in attempt.answers)
            (
              text.question(channel.id, a.questionId),
              text.choice(channel.id, a.questionId, a.choiceId),
            ),
        ],
        examples: [
          for (var i = 0; i < channel.archetypeCount; i++) ...text.archetypeLines(channel.id, i),
        ],
        fallbackLines: text.archetypeLines(channel.id, attempt.archetype),
      );

  /// 재료를 현재 언어 문장으로 푼다.
  static ResolvedMaterial resolve(
    MaterialRef ref,
    int currentIndex,
    TextBook text,
  ) =>
      ResolvedMaterial(
        kind: ref.kind,
        ago: currentIndex - ref.sourceIndex,
        channelName: text.channelName(ref.channelId),
        choiceText: text.choice(ref.channelId, ref.questionId, ref.choiceId),
      );
}
