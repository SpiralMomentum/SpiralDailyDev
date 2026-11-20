import 'dart:math';

import '../entities/accumulation.dart';
import '../entities/catalog.dart';
import 'manifestation_gauge.dart';
import 'material_selector.dart';
import 'personality_scorer.dart';

/// 누적 한 단계의 결과. [next] 는 시행이 추가되고 게이지가 갱신된 누적,
/// [manifestation] 은 이번 시행에서 발현이 확정되면 그 기록 (없으면 null).
typedef AccumulationAdvance = ({
  AccumulationState next,
  ManifestationRecord? manifestation,
});

/// 시행 기록 추가, 발현 판정, 게이지 갱신을 한 번에 하는 순수 정책.
/// 난수 소비 순서: 게이지 굴림, 재료 선택, 발현 형태, 발현 이론, 게이지 갱신.
/// 이 순서를 바꾸면 같은 시드의 시뮬레이션 결과가 달라진다.
abstract final class AccumulationStep {
  static AccumulationAdvance advance(
    AccumulationState state,
    AttemptRecord attempt, {
    required List<Theory> theories,
    required Random random,
  }) {
    final manifestation = _manifest(state, attempt, theories, random);
    final next = state.copyWith(
      attempts: [...state.attempts, attempt],
      manifestations: [...state.manifestations, ?manifestation],
      gaugePermille: ManifestationGauge.next(
        state.gaugePermille,
        manifested: manifestation != null,
        random: random,
      ),
    );
    return (next: next, manifestation: manifestation);
  }

  static ManifestationRecord? _manifest(
    AccumulationState state,
    AttemptRecord attempt,
    List<Theory> theories,
    Random random,
  ) {
    if (!ManifestationGauge.roll(state.gaugePermille, random)) return null;
    final materials = MaterialSelector.select(
      pastAttempts: state.attempts,
      pastManifestations: state.manifestations,
      random: random,
    );
    if (materials.isEmpty) return null;
    return ManifestationRecord(
      attemptIndex: attempt.index,
      form: random.nextBool()
          ? ManifestationForm.mixed
          : ManifestationForm.separate,
      materials: materials,
      theoryId: TheoryPicker.pick(
        theories,
        random,
        avoid: attempt.theoryId,
      )?.id,
    );
  }
}
