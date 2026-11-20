import 'dart:math';

import 'package:utils/utils.dart';

import '../entities/evaluation.dart';

/// 온디바이스 모델 경계. 결과 대사와 누적 발현 대사를 만든다.
/// 기본 구현은 Gemma 4 E2B(LLM) 이고, 실패하면 템플릿 엔진으로 대체한다.
abstract interface class NarrationEngine {
  Future<Result<Narration>> baseLines(BaseNarrationRequest request, Random random);

  Future<Result<ManifestationText>> manifestation(
    ManifestationRequest request,
    Random random,
  );
}
