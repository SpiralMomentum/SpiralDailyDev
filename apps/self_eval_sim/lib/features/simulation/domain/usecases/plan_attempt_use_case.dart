import 'dart:math';

import 'package:utils/utils.dart';

import '../entities/accumulation.dart';
import '../entities/catalog.dart';
import '../entities/evaluation.dart';
import '../policies/archetype_resolver.dart';
import '../policies/manifestation_gauge.dart';
import '../policies/material_selector.dart';
import '../repositories/accumulation_repository.dart';

/// 답변을 누적에 기록하고 이번 시행의 발현 여부와 재료를 확정한다.
/// 문장 생성 전에 저장까지 마치므로, 생성 도중 앱이 꺼져도 누적은 남는다.
class PlanAttemptUseCase {
  const PlanAttemptUseCase(this._repository, this._random, this._clock);

  final AccumulationRepository _repository;
  final Random _random;
  final DateTime Function() _clock;

  Future<Result<AttemptPlan>> call({
    required Channel channel,
    required List<Answer> answers,
  }) async {
    final loaded = await _repository.load();
    if (loaded case ErrorResult(:final failure)) return ErrorResult(failure);
    final state = loaded.dataOrNull!;

    final attempt = AttemptRecord(
      index: state.nextAttemptIndex,
      channelId: channel.id,
      answers: answers,
      archetype: ArchetypeResolver.resolve(channel, answers),
      at: _clock(),
    );
    final manifestation = _manifest(state, attempt);
    final next = state.copyWith(
      attempts: [...state.attempts, attempt],
      manifestations: [
        ...state.manifestations,
        ?manifestation,
      ],
      gaugePermille: ManifestationGauge.next(
        state.gaugePermille,
        manifested: manifestation != null,
        random: _random,
      ),
    );
    final saved = await _repository.save(next);
    return saved.map(
      (_) => AttemptPlan(
        channelId: channel.id,
        attempt: attempt,
        manifestation: manifestation,
      ),
    );
  }

  ManifestationRecord? _manifest(AccumulationState state, AttemptRecord attempt) {
    if (!ManifestationGauge.roll(state.gaugePermille, _random)) return null;
    final materials = MaterialSelector.select(
      pastAttempts: state.attempts,
      pastManifestations: state.manifestations,
      random: _random,
    );
    if (materials.isEmpty) return null;
    return ManifestationRecord(
      attemptIndex: attempt.index,
      form: _random.nextBool() ? ManifestationForm.mixed : ManifestationForm.separate,
      materials: materials,
    );
  }
}
