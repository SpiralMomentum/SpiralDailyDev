import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/domain/policies/manifestation_gauge.dart';

import '../../../support/fixtures.dart';

void main() {
  group('ManifestationGauge.roll', () {
    test('확률 0 이면 난수와 상관없이 발현하지 않는다 (시작 0%)', () {
      expect(ManifestationGauge.roll(0, ScriptedRandom(intValue: 0)), isFalse);
    });

    test('천장(1000)에 닿으면 반드시 발현한다', () {
      expect(ManifestationGauge.roll(1000, ScriptedRandom(intValue: 999)), isTrue);
    });

    test('난수가 확률보다 작을 때만 발현한다', () {
      expect(ManifestationGauge.roll(300, ScriptedRandom(intValue: 299)), isTrue);
      expect(ManifestationGauge.roll(300, ScriptedRandom(intValue: 300)), isFalse);
    });

    test('확률 p 에서 10만 회 추첨한 발현 비율은 p 와 0.5%p 이내로 같다', () {
      final random = Random(42);
      const trials = 100000;
      final hits = List.generate(trials, (_) => ManifestationGauge.roll(250, random))
          .where((e) => e)
          .length;
      expect(hits / trials, closeTo(0.25, 0.005));
    });
  });

  group('ManifestationGauge.next', () {
    test('발현하면 0 으로 초기화한다', () {
      expect(ManifestationGauge.next(640, manifested: true, random: Random(1)), 0);
    });

    test('증가폭은 1~100 천분율(0.1%p~10%p)이다', () {
      expect(ManifestationGauge.next(0, manifested: false, random: ScriptedRandom(intValue: 0)), 1);
      expect(ManifestationGauge.next(0, manifested: false, random: ScriptedRandom(intValue: 999)), 100);
      final random = Random(7);
      for (var i = 0; i < 10000; i++) {
        final inc = ManifestationGauge.next(0, manifested: false, random: random);
        expect(inc, inInclusiveRange(1, 100));
      }
    });

    test('천장 1000 을 넘지 않는다', () {
      expect(
        ManifestationGauge.next(990, manifested: false, random: ScriptedRandom(intValue: 99)),
        1000,
      );
    });
  });
}
