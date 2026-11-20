import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/policies/material_selector.dart';

import '../../../support/fixtures.dart';

void main() {
  // 시행마다 선택이 달라 서로 다른 선택(문항 3 x 선택지 3 = 9가지)이 후보가 된다.
  final attempts = [
    for (var i = 1; i <= 6; i++) attempt(i, choices: [for (var q = 0; q < 3; q++) 'c${(i + q) % 3 + 1}']),
  ];

  test('재료 5개 기준 과거 발현 3 : 개별 시행 2 (6:4)', () {
    expect(MaterialSelector.manifestationQuota(5), 3);
    final manifestations = [
      ManifestationRecord(
        attemptIndex: 3,
        form: ManifestationForm.mixed,
        materials: [
          ref(MaterialKind.attempt, 1, c: 'c1'),
          ref(MaterialKind.attempt, 2, c: 'c2'),
          ref(MaterialKind.attempt, 2, q: 'q2', c: 'c3'),
          ref(MaterialKind.attempt, 1, q: 'q3', c: 'c2'),
        ],
      ),
    ];
    final picked = MaterialSelector.select(
      pastAttempts: attempts,
      pastManifestations: manifestations,
      random: Random(3),
    );
    expect(picked, hasLength(5));
    expect(picked.where((r) => r.kind == MaterialKind.manifestation), hasLength(3));
    expect(picked.where((r) => r.kind == MaterialKind.attempt), hasLength(2));
  });

  test('과거 발현이 없으면 개별 시행 재료로 5개를 채운다', () {
    final picked = MaterialSelector.select(
      pastAttempts: attempts,
      pastManifestations: const [],
      random: Random(1),
    );
    expect(picked, hasLength(5));
    expect(picked.every((r) => r.kind == MaterialKind.attempt), isTrue);
  });

  test('발현 재료는 과거 발현의 시행 순번을 출처로 가진다', () {
    final pool = MaterialSelector.manifestationPool([
      ManifestationRecord(
        attemptIndex: 4,
        form: ManifestationForm.separate,
        materials: [ref(MaterialKind.attempt, 1)],
      ),
    ]);
    expect(pool.single.kind, MaterialKind.manifestation);
    expect(pool.single.sourceIndex, 4);
  });

  test('후보가 없으면 빈 목록', () {
    expect(
      MaterialSelector.select(pastAttempts: const [], pastManifestations: const [], random: Random(1)),
      isEmpty,
    );
  });

  group('같은 누적 조합 회피', () {
    // 시행 1 (선택 3개) 과, 재료가 [발현9:q1~q3, 시행1:q1, 시행1:q2] 인 과거 발현 하나.
    // 발현 후보 5개 중 3개(10가지) x 시행 후보 3개 중 2개(3가지) = 30가지 조합 중 하나가 이미 쓰인 조합이다.
    final past = [attempt(1, choices: ['c1', 'c2', 'c3'])];
    final usedMaterials = [
      ref(MaterialKind.manifestation, 9, q: 'q1'),
      ref(MaterialKind.manifestation, 9, q: 'q2'),
      ref(MaterialKind.manifestation, 9, q: 'q3'),
      ref(MaterialKind.attempt, 1, q: 'q1'),
      ref(MaterialKind.attempt, 1, q: 'q2', c: 'c2'),
    ];
    final used = ManifestationRecord(attemptIndex: 9, form: ManifestationForm.mixed, materials: usedMaterials);

    test('다른 조합이 있으면 이미 쓴 조합을 내지 않는다 (시드 300개)', () {
      final usedSignature = MaterialSelector.signature(usedMaterials);
      for (var seed = 0; seed < 300; seed++) {
        final next = MaterialSelector.select(pastAttempts: past, pastManifestations: [used], random: Random(seed));
        expect(MaterialSelector.signature(next), isNot(usedSignature), reason: 'seed $seed');
      }
    });

    test('가능한 조합이 하나뿐이면 다시 뽑기를 포기하고 그 조합을 쓴다', () {
      // 발현 후보 {발현9:q1.c1, 발현9:q1.c9}, 시행 후보 q1.c1 은 이미 쓴 선택이라 제외 -> 조합은 하나뿐.
      final materials = [ref(MaterialKind.manifestation, 9), ref(MaterialKind.manifestation, 9, c: 'c9')];
      final only = ManifestationRecord(attemptIndex: 9, form: ManifestationForm.mixed, materials: materials);
      final next = MaterialSelector.select(
        pastAttempts: [attempt(1, choices: ['c1'])],
        pastManifestations: [only],
        random: Random(1),
      );
      expect(MaterialSelector.signature(next), MaterialSelector.signature(materials));
    });
  });

  test('한 발현 안에서 같은 선택은 한 번만 쓴다 (시드 200개)', () {
    // 같은 선택 q1.c1 이 과거 발현 세 번과 시행 다섯 번에 모두 들어 있다.
    final past = [for (var i = 1; i <= 5; i++) attempt(i, choices: ['c1', 'c2'])];
    final manifestations = [
      for (final at in [2, 3, 4])
        ManifestationRecord(attemptIndex: at, form: ManifestationForm.mixed, materials: [ref(MaterialKind.attempt, 1)]),
    ];
    for (var seed = 0; seed < 200; seed++) {
      final picked = MaterialSelector.select(pastAttempts: past, pastManifestations: manifestations, random: Random(seed));
      final keys = picked.map((r) => r.choiceKey).toList();
      expect(keys.toSet(), hasLength(keys.length), reason: 'seed $seed $keys');
      expect(keys.toSet(), {'wuxia.q1.c1', 'wuxia.q2.c2'});
    }
  });

  test('같은 시행 순번과 선택은 발현 후보에 한 번만 들어간다', () {
    final m = ManifestationRecord(
      attemptIndex: 5,
      form: ManifestationForm.mixed,
      materials: [ref(MaterialKind.attempt, 1), ref(MaterialKind.manifestation, 1)],
    );
    expect(MaterialSelector.manifestationPool([m]), hasLength(1));
  });
}
