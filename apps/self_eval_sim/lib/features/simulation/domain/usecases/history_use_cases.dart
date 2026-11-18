import 'package:equatable/equatable.dart';
import 'package:utils/utils.dart';

import '../repositories/accumulation_repository.dart';

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

/// 누적 기록 전체 삭제 (명세: 보관 기간 무제한, 전체 삭제 가능).
class ClearHistoryUseCase {
  const ClearHistoryUseCase(this._repository);

  final AccumulationRepository _repository;

  Future<Result<void>> call() => _repository.clear();
}
