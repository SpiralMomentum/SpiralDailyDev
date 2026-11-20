import 'dart:math';

import '../entities/accumulation.dart';

/// 발현 재료 선택 규칙 (명세 1절 "재료 규칙", "발현 기록").
/// - 과거 발현 6 : 개별 시행 4. 재료 5개 기준 3 : 2.
/// - 과거 발현 재료가 모자라면 개별 시행 재료로 채운다.
/// - 한 번의 발현 안에서 같은 선택(채널+문항+선택지)은 한 번만 쓴다. 발현이 다음 발현의 재료가 되면서
///   같은 선택이 불어나 한 발현에 여러 번 들어가는 것을 막는다 (시뮬레이션에서 확인된 문제).
/// - 이전 발현과 같은 재료 조합(서명)은 피한다. [maxRerolls] 번 다시 뽑아도
///   겹치면 마지막 조합을 그대로 쓴다.
abstract final class MaterialSelector {
  static const int totalMaterials = 5;
  static const int manifestationShareNumerator = 6;
  static const int shareDenominator = 10;
  static const int maxRerolls = 30;

  static int manifestationQuota(int total) =>
      (total * manifestationShareNumerator / shareDenominator).round();

  /// 과거 개별 시행의 모든 선택을 재료 후보로 펼친다.
  static List<MaterialRef> attemptPool(List<AttemptRecord> attempts) => [
        for (final a in attempts)
          for (final answer in a.answers)
            MaterialRef(
              kind: MaterialKind.attempt,
              sourceIndex: a.index,
              channelId: a.channelId,
              questionId: answer.questionId,
              choiceId: answer.choiceId,
            ),
      ];

  /// 과거 발현이 썼던 재료를 다시 재료 후보로 만든다. 같은 선택은 한 번만 남긴다.
  static List<MaterialRef> manifestationPool(
    List<ManifestationRecord> manifestations,
  ) {
    final seen = <String>{};
    return [
      for (final m in manifestations)
        for (final ref in m.materials)
          if (seen.add('${m.attemptIndex}:${ref.choiceKey}'))
            MaterialRef(
              kind: MaterialKind.manifestation,
              sourceIndex: m.attemptIndex,
              channelId: ref.channelId,
              questionId: ref.questionId,
              choiceId: ref.choiceId,
            ),
    ];
  }

  static String signature(Iterable<MaterialRef> refs) =>
      (refs.map((r) => r.signatureToken).toList()..sort()).join('|');

  /// 섞은 후보에서 [taken] 에 없는 선택만 [count] 개까지 고른다.
  static List<MaterialRef> _pick(
    List<MaterialRef> pool,
    int count,
    Random random,
    Set<String> taken,
  ) {
    final picked = <MaterialRef>[];
    for (final ref in List<MaterialRef>.of(pool)..shuffle(random)) {
      if (picked.length >= count) break;
      if (taken.add(ref.choiceKey)) picked.add(ref);
    }
    return picked;
  }

  static List<MaterialRef> _draw(
    List<MaterialRef> attempts,
    List<MaterialRef> manifestations,
    Random random,
  ) {
    final taken = <String>{};
    final fromManifest = _pick(manifestations, manifestationQuota(totalMaterials), random, taken);
    final fromAttempts = _pick(attempts, totalMaterials - fromManifest.length, random, taken);
    return [...fromManifest, ...fromAttempts];
  }

  /// 재료를 고른다. 후보가 하나도 없으면 빈 목록.
  static List<MaterialRef> select({
    required List<AttemptRecord> pastAttempts,
    required List<ManifestationRecord> pastManifestations,
    required Random random,
  }) {
    final attempts = attemptPool(pastAttempts);
    final manifestations = manifestationPool(pastManifestations);
    final used = pastManifestations.map((m) => signature(m.materials)).toSet();
    var drawn = _draw(attempts, manifestations, random);
    for (var i = 0; i < maxRerolls && used.contains(signature(drawn)); i++) {
      drawn = _draw(attempts, manifestations, random);
    }
    return drawn;
  }
}
