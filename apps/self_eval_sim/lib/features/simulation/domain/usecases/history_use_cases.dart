import 'package:equatable/equatable.dart';
import 'package:utils/utils.dart';

import '../repositories/accumulation_repository.dart';
import '../story/story_repository.dart';

final class HistorySummary extends Equatable {
  const HistorySummary({required this.attempts, required this.manifestations});

  final int attempts;
  final int manifestations;

  @override
  List<Object?> get props => [attempts, manifestations];
}

class GetHistorySummaryUseCase {
  const GetHistorySummaryUseCase(this._repository);

  final AccumulationRepository _repository;

  Future<Result<HistorySummary>> call() async => (await _repository.load()).map(
        (s) => HistorySummary(
          attempts: s.attempts.length,
          manifestations: s.manifestations.length,
        ),
      );
}

/// 누적 기록과 이야기 기록 전체 삭제 (명세: 보관 기간 무제한, 전체 삭제 가능).
/// 둘 다 지우려 시도하고, 하나라도 실패하면 첫 실패를 돌려준다.
class ClearHistoryUseCase {
  const ClearHistoryUseCase(this._accumulation, this._story);

  final AccumulationRepository _accumulation;
  final StoryRepository _story;

  Future<Result<void>> call() async {
    final results = [await _accumulation.clear(), await _story.clear()];
    return results.firstWhere((r) => !r.isSuccess, orElse: () => results.first);
  }
}
