import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ingest/domain/ingest.dart';
import '../domain/transaction.dart';

final class EditState extends Equatable {
  const EditState({
    required this.tx,
    this.saving = false,
    this.saved = false,
    this.failed = false,
  });

  final Transaction tx;
  final bool saving;
  final bool saved;

  /// 마지막 저장이 실패했다. 화면은 닫지 않고 다시 시도하게 한다.
  final bool failed;

  /// 취소·중복 거래는 고칠 수 없다.
  bool get editable =>
      tx.status != TxStatus.cancelled && tx.status != TxStatus.duplicate;

  @override
  List<Object?> get props => [tx, saving, saved, failed];
}

/// 저장 후 상태. 포함은 금액이 있을 때만, 포함 해제는 포함된 거래만 제외로 바꾼다.
TxStatus editedStatus(
  TxStatus current, {
  required bool include,
  required int amount,
}) {
  if (include && amount != 0) return TxStatus.included;
  if (!include && current == TxStatus.included) return TxStatus.excluded;
  return current;
}

/// 입력한 금액(절댓값)의 부호. 환불 분류면 음수, 그 밖에는 원래 거래의 부호를 따른다.
int signedAmount(int abs, SpendCategory category, {required int original}) =>
    category == SpendCategory.refund || original < 0 ? -abs : abs;

class EditCubit extends Cubit<EditState> {
  EditCubit(this._deps, Transaction tx) : super(EditState(tx: tx));

  final IngestDeps _deps;

  Future<void> save({
    required int amount,
    required String counterparty,
    required DateTime occurredAt,
    required SpendCategory category,
    required bool include,
  }) async {
    final current = state.tx;
    final status = editedStatus(
      current.status,
      include: include,
      amount: amount,
    );
    // 대기 거래의 포함은 확정 경로로 처리해 확인 알림도 거둔다.
    final resolvesPending =
        current.status == TxStatus.pending && status == TxStatus.included;
    final edited = current.copyWith(
      amount: amount,
      counterparty: counterparty,
      occurredAt: occurredAt,
      category: category,
      status: resolvesPending ? TxStatus.pending : status,
    );
    emit(EditState(tx: current, saving: true));
    try {
      await saveEdit(edited, _deps);
      if (resolvesPending) await resolveCandidate(edited.id, true, _deps);
    } catch (e, st) {
      addError(e, st);
      // 일부만 반영됐을 수 있으므로 저장된 값을 기준으로 다시 시도하게 한다.
      emit(EditState(tx: await _storedOr(current), failed: true));
      return;
    }
    emit(EditState(tx: await _storedOr(edited), saved: true));
  }

  Future<Transaction> _storedOr(Transaction fallback) async {
    try {
      return await _deps.ledger.byId(fallback.id) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}
