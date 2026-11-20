import 'dart:math';

import 'package:utils/utils.dart';

import '../../domain/entities/evaluation.dart';
import '../../domain/repositories/narration_engine.dart';

/// [primary](모델)가 실패하면 [fallback](템플릿)으로 대체한다.
/// 별도 발현 장면의 화자/장소 이름은 언어별 템플릿 팩 값을 쓴다.
class FallbackNarrationEngine implements NarrationEngine {
  const FallbackNarrationEngine(this.primary, this.fallback, {this.onPrimaryFailure});

  final NarrationEngine primary;
  final NarrationEngine fallback;

  /// 모델 실패를 기록할 곳 (로그, 리포트). 사용자 화면에는 영향 없음.
  final void Function(String kind, Failure failure)? onPrimaryFailure;

  @override
  Future<Result<Narration>> baseLines(BaseNarrationRequest request, Random random) async {
    final first = await primary.baseLines(request, random);
    if (first case ErrorResult(:final failure)) {
      onPrimaryFailure?.call('base', failure);
      return fallback.baseLines(request, random);
    }
    return first;
  }

  @override
  Future<Result<ManifestationText>> manifestation(
    ManifestationRequest request,
    Random random,
  ) async {
    final template = await fallback.manifestation(request, random);
    final first = await primary.manifestation(request, random);
    if (first case Success(:final data)) {
      final names = template.dataOrNull;
      return Success(
        ManifestationText(
          lines: data.lines,
          separateSpeaker: names?.separateSpeaker ?? data.separateSpeaker,
          separatePlace: names?.separatePlace ?? data.separatePlace,
          source: NarrationSource.model,
        ),
      );
    }
    if (first case ErrorResult(:final failure)) onPrimaryFailure?.call('manifestation', failure);
    return template;
  }
}
