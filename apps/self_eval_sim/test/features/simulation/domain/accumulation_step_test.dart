import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/catalog.dart';
import 'package:self_eval_sim/features/simulation/domain/policies/accumulation_step.dart';
import 'package:self_eval_sim/features/simulation/domain/policies/manifestation_gauge.dart';
import 'package:self_eval_sim/features/simulation/domain/policies/material_selector.dart';
import 'package:self_eval_sim/features/simulation/domain/policies/personality_scorer.dart';

import '../../../support/fixtures.dart';

void main() {
  const theories = [
    Theory(
      id: 't1',
      mode: TheoryMode.dominant,
      axes: [
        ['a', 'b'],
      ],
    ),
    Theory(
      id: 't2',
      mode: TheoryMode.dominant,
      axes: [
        ['c', 'd'],
      ],
    ),
  ];

  group('AccumulationStep.advance', () {
    test('게이지 1000 이고 과거 기록이 있으면 발현이 생기고 게이지가 초기화된다', () {
      final state = AccumulationState(
        attempts: [attempt(1), attempt(2)],
        gaugePermille: 1000,
      );
      final result = AccumulationStep.advance(
        state,
        attempt(3),
        theories: theories,
        random: Random(1),
      );
      expect(result.manifestation, isNotNull);
      expect(result.manifestation!.attemptIndex, 3);
      expect(
        result.next.gaugePermille,
        ManifestationGauge.next(1000, manifested: true, random: Random(1)),
      );
      expect(result.next.gaugePermille, 0);
      expect(result.next.manifestations.single, result.manifestation);
    });

    test('게이지 0 이면 발현 없음, 시행은 추가된다', () {
      final state = AccumulationState(attempts: [attempt(1)]);
      final result = AccumulationStep.advance(
        state,
        attempt(2),
        theories: theories,
        random: Random(1),
      );
      expect(result.manifestation, isNull);
      expect(result.next.attempts.last, attempt(2));
      expect(result.next.attempts, hasLength(2));
      expect(result.next.manifestations, isEmpty);
      expect(result.next.gaugePermille, inInclusiveRange(1, 100));
    });

    test('같은 시드면 이전 _manifest 순서(굴림 -> 재료 -> 형태 -> 이론)와 같은 결과', () {
      final state = AccumulationState(
        attempts: [attempt(1), attempt(2)],
        gaugePermille: 1000,
      );
      final current = attempt(3);

      final replay = Random(7);
      final materials = MaterialSelector.select(
        pastAttempts: state.attempts,
        pastManifestations: state.manifestations,
        random: replay,
      );
      final expected = ManifestationRecord(
        attemptIndex: 3,
        form: replay.nextBool()
            ? ManifestationForm.mixed
            : ManifestationForm.separate,
        materials: materials,
        theoryId: TheoryPicker.pick(theories, replay)?.id,
      );

      final result = AccumulationStep.advance(
        state,
        current,
        theories: theories,
        random: Random(7),
      );
      expect(result.manifestation, expected);
    });
  });
}
