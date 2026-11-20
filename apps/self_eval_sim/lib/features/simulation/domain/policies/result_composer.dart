import '../entities/accumulation.dart';
import '../entities/catalog.dart';
import '../entities/evaluation.dart';
import '../entities/text_book.dart';
import 'personality_scorer.dart';

/// 결과 장면을 조립하는 순수 함수 모음.
abstract final class ResultComposer {
  /// 결과 장면.
  /// - 첫 줄: 결과 유형을 밝히는 고정 문장 (예: `당신은 깊은 바다의 사파이어처럼 보이네요.`)
  /// - 가운데: 왜 그 유형인지 성격으로 설명하는 [lines] (모델 대사, 없으면 콘텐츠 대체 대사)
  /// - 끝 줄: 결과 유형에 맞는 채널 분위기의 명언풍 문장. [sayingIndex] 로 2개 중 하나를 고른다.
  static Scene baseScene(
    Channel channel,
    int archetype,
    TextBook text, {
    List<String>? lines,
    int sayingIndex = 0,
  }) => Scene(
    kind: SceneKind.base,
    art: channel.art,
    place: text.place(channel.id),
    speaker: text.speaker(channel.id),
    lines: [
      text.reveal(channel.id, text.archetypeTitle(channel.id, archetype)),
      ...(lines ?? text.archetypeLines(channel.id, archetype)),
      text.saying(channel.id, archetype, sayingIndex),
    ],
  );

  /// 모델을 쓸 수 없을 때의 성격 설명: 유형 설명 + 장점 + 약점. 성격 유형이 없으면 채널 대사.
  /// 이론 이름과 유형 이름은 사용자에게 보이지 않는다 (설명 문장만 씀).
  static List<String> fallbackLines(
    Channel channel,
    int archetype,
    TextBook text,
    TraitReading? reading,
  ) {
    if (reading == null) return text.archetypeLines(channel.id, archetype);
    final p = text.typeProfile(reading.theoryId, reading.outcome);
    return [p.description, p.strength, p.weakness];
  }

  /// 발현 형태에 따라 장면을 섞는다.
  /// - mixed: 기본 장면 대사 뒤에 발현 대사를 이어 붙인다.
  /// - separate: 기본 장면 뒤에 별도 발현 장면을 붙인다.
  static List<Scene> withManifestation(
    Scene base,
    ManifestationForm form,
    ManifestationText manifest,
  ) => switch (form) {
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
    final reading = plan.reading;
    final scene = baseScene(
      channel,
      plan.attempt.archetype,
      text,
      lines:
          base?.lines ??
          fallbackLines(channel, plan.attempt.archetype, text, reading),
      // 시행 순번으로 명언을 번갈아 써서 같은 결과가 다시 나와도 끝 줄이 바뀌게 한다.
      sayingIndex: plan.attempt.index,
    );
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
      reading: reading,
      deepReading: manifest == null ? null : plan.deepReading,
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

  /// 한 선택이 [theoryId] 에서 드러낸 성향 이름들 (예: `외향성 높음, 신경성 낮음`, `내향, 판단`).
  static String traitText(
    ContentCatalog catalog,
    TextBook text,
    String theoryId,
    String channelId,
    String questionId,
    String choiceId,
  ) => PersonalityScorer.polesOf(
    catalog,
    channelId,
    questionId,
    choiceId,
    theoryId,
  ).map((p) => plainLabel(text.poleLabel(theoryId, p))).join(', ');

  /// 프롬프트용 성향 이름. 유형 번호/코드(`5번 · `, `(E)`)를 떼어 이론이 드러나지 않게 한다.
  static String plainLabel(String label) =>
      label.split(' · ').last.replaceAll(RegExp(r'\s*\([A-Z]\)'), '').trim();

  /// 개별 시행 대사 생성 요청을 만든다.
  static BaseNarrationRequest baseRequest(
    Channel channel,
    AttemptPlan plan,
    TextBook text, {
    ContentCatalog? catalog,
  }) {
    final attempt = plan.attempt;
    final reading = plan.reading;
    return BaseNarrationRequest(
      languageCode: text.languageCode,
      speaker: text.speaker(channel.id),
      place: text.place(channel.id),
      title: text.archetypeTitle(channel.id, attempt.archetype),
      answers: [
        for (final a in attempt.answers)
          (
            text.question(channel.id, a.questionId),
            text.choice(channel.id, a.questionId, a.choiceId),
            reading == null || catalog == null
                ? ''
                : traitText(
                    catalog,
                    text,
                    reading.theoryId,
                    channel.id,
                    a.questionId,
                    a.choiceId,
                  ),
          ),
      ],
      examples: [
        for (var i = 0; i < channel.archetypeCount; i++)
          ...text.archetypeLines(channel.id, i),
      ],
      fallbackLines: fallbackLines(channel, attempt.archetype, text, reading),
      profile: reading == null
          ? null
          : text.typeProfile(reading.theoryId, reading.outcome),
      reveal: text.reveal(
        channel.id,
        text.archetypeTitle(channel.id, attempt.archetype),
      ),
      style: text.style(channel.id),
      avoid: text.avoid(channel.id),
    );
  }

  /// 누적 발현 대사 생성 요청을 만든다.
  static ManifestationRequest manifestationRequest(
    Channel channel,
    AttemptPlan plan,
    TextBook text, {
    ContentCatalog? catalog,
    List<String> examples = const [],
  }) {
    final manifestation = plan.manifestation!;
    final deep = plan.deepReading;
    return ManifestationRequest(
      languageCode: text.languageCode,
      form: manifestation.form,
      speaker: text.speaker(channel.id),
      title: text.archetypeTitle(channel.id, plan.attempt.archetype),
      materials: [
        for (final ref in supportingFirst(manifestation.materials, catalog, deep))
          resolve(
            ref,
            plan.attempt.index,
            text,
            catalog: catalog,
            theoryId: deep?.theoryId,
          ),
      ],
      examples: examples,
      profile: deep == null
          ? null
          : text.typeProfile(deep.theoryId, deep.outcome),
      tally: deep == null
          ? const []
          : ([
              for (final e in deep.tally.entries)
                (plainLabel(text.poleLabel(deep.theoryId, e.key)), e.value),
            ]..sort((a, b) => b.$2.compareTo(a.$2))),
      totalAnswers: deep?.answers ?? 0,
      today: [
        for (final a in plan.attempt.answers)
          text.choice(channel.id, a.questionId, a.choiceId),
      ],
      style: manifestation.form == ManifestationForm.mixed
          ? text.style(channel.id)
          : '',
      avoid: text.avoid(channel.id),
    );
  }

  /// 재료를 누적 유형과 맞는 정도가 높은 순으로 정렬한다 (같으면 원래 순서).
  /// 모델이 누적 유형과 다른 성향의 기록을 근거로 삼는 일을 줄이기 위함이다.
  static List<MaterialRef> supportingFirst(
    List<MaterialRef> materials,
    ContentCatalog? catalog,
    TraitReading? deep,
  ) {
    final theory = catalog?.theoryById(deep?.theoryId);
    if (catalog == null || deep == null || theory == null) return materials;
    int support(MaterialRef m) {
      final poles = PersonalityScorer.polesOf(catalog, m.channelId, m.questionId, m.choiceId, theory.id);
      return switch (theory.mode) {
        TheoryMode.dominant => poles.contains(deep.outcome) ? 1 : 0,
        TheoryMode.code => poles.where(deep.outcome.contains).length,
      };
    }

    final indexed = materials.indexed.toList()
      ..sort((a, b) {
        final bySupport = support(b.$2).compareTo(support(a.$2));
        return bySupport != 0 ? bySupport : a.$1.compareTo(b.$1);
      });
    return [for (final e in indexed) e.$2];
  }

  /// 재료를 현재 언어 문장으로 푼다. [theoryId] 가 있으면 그 이론에서 드러낸 성향도 붙인다.
  static ResolvedMaterial resolve(
    MaterialRef ref,
    int currentIndex,
    TextBook text, {
    ContentCatalog? catalog,
    String? theoryId,
  }) => ResolvedMaterial(
    kind: ref.kind,
    ago: currentIndex - ref.sourceIndex,
    channelName: text.channelName(ref.channelId),
    choiceText: text.choice(ref.channelId, ref.questionId, ref.choiceId),
    trait: catalog == null || theoryId == null
        ? ''
        : traitText(
            catalog,
            text,
            theoryId,
            ref.channelId,
            ref.questionId,
            ref.choiceId,
          ),
  );
}
