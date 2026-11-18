import 'dart:math';


import '../entities/accumulation.dart';
import '../entities/catalog.dart';
import '../entities/evaluation.dart';
import '../entities/text_book.dart';
import '../policies/result_composer.dart';
import '../repositories/narration_engine.dart';

/// 확정된 시행 계획으로 결과 장면을 만든다 (온디바이스 모델이 도는, 대기 시간이 생기는 단계).
/// - 기본 결과 대사: 모델이 만들지 못하면 콘텐츠 대사.
/// - 발현 대사: 엔진이 만들지 못하면 발현 없이 기본 결과. 발현 기록은 계획 단계에서
///   이미 저장되었으므로 다음 발현의 재료로는 계속 쓰인다.
class ComposeResultUseCase {
  const ComposeResultUseCase(this._engine, this._random);

  final NarrationEngine _engine;
  final Random _random;

  Future<EvaluationResult> call({
    required Channel channel,
    required AttemptPlan plan,
    required TextBook text,
  }) async {
    final baseRequest = ResultComposer.baseRequest(channel, plan.attempt, text);
    final base = await _engine.baseLines(baseRequest, _random);
    final manifestation = plan.manifestation;
    final manifest = manifestation == null
        ? null
        : await _engine.manifestation(
            ManifestationRequest(
              languageCode: text.languageCode,
              form: manifestation.form,
              speaker: text.speaker(channel.id),
              title: text.archetypeTitle(channel.id, plan.attempt.archetype),
              materials: [
                for (final ref in manifestation.materials)
                  ResultComposer.resolve(ref, plan.attempt.index, text),
              ],
              examples: manifestation.form == ManifestationForm.mixed
                  ? baseRequest.examples
                  : const [],
            ),
            _random,
          );
    return ResultComposer.compose(
      channel: channel,
      plan: plan,
      text: text,
      base: base.dataOrNull,
      manifest: manifest?.dataOrNull,
    );
  }
}
