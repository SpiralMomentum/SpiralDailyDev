import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ingest/domain/ingest.dart';
import '../domain/transaction.dart';

final class CandidatesState extends Equatable {
  const CandidatesState({
    this.waiting = const [],
    this.needsReview = const [],
    this.auto = const [],
    this.loading = true,
  });

  /// 확인 대기(알림을 보낸 후보).
  final List<Transaction> waiting;

  /// 금액·종류를 알 수 없어 직접 고쳐야 하는 후보.
  final List<Transaction> needsReview;

  /// 최근 90일 동안 자동으로 제외된 거래(내부이체·선불 머니 사용·중복).
  final List<Transaction> auto;
  final bool loading;

  @override
  List<Object?> get props => [waiting, needsReview, auto, loading];
}

const Duration _autoWindow = Duration(days: 90);

/// 대기 거래를 둘로 나누고, 최근 거래에서 자동 제외 목록을 고른다(최신순).
CandidatesState splitCandidates({
  required List<Transaction> pending,
  required List<Transaction> recent,
}) {
  bool autoExcluded(Transaction t) =>
      t.status == TxStatus.duplicate ||
      (t.status == TxStatus.excluded &&
          (t.category == SpendCategory.internal ||
              t.category == SpendCategory.prepaidUse));
  return CandidatesState(
    waiting: [
      for (final t in pending)
        if (!t.needsReview) t,
    ],
    needsReview: [
      for (final t in pending)
        if (t.needsReview) t,
    ],
    auto: recent.where(autoExcluded).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)),
    loading: false,
  );
}

class CandidatesCubit extends Cubit<CandidatesState> {
  CandidatesCubit(this._deps) : super(const CandidatesState());

  final IngestDeps _deps;

  Future<void> load() async {
    final pending = await _deps.ledger.byStatus({TxStatus.pending});
    final recent = await _deps.ledger.since(_deps.now().subtract(_autoWindow));
    emit(splitCandidates(pending: pending, recent: recent));
  }

  Future<void> include(String id) => _resolve(id, true);

  Future<void> exclude(String id) => _resolve(id, false);

  /// 알림 취소가 실패해도 저장은 끝났으므로 목록은 다시 읽는다.
  Future<void> _resolve(String id, bool include) async {
    try {
      await resolveCandidate(id, include, _deps);
    } catch (e, st) {
      addError(e, st);
    }
    await load();
  }
}
