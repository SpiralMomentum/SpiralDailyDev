import 'transaction.dart';

abstract interface class LedgerRepository {
  Future<void> upsertAll(List<Transaction> txs);
  Future<Transaction?> byId(String id);
  Future<List<Transaction>> since(DateTime from);
  Future<List<Transaction>> byStatus(Set<TxStatus> statuses);

  /// 확인 대기 거래만 [status]로 바꾼다. 실제로 바뀌었을 때만 true.
  /// 읽고 쓰는 사이에 다른 수집이 상태를 바꿔도 덮어쓰지 않도록 한 문장으로 처리한다.
  Future<bool> resolvePending(
    String id,
    TxStatus status, {
    required bool clearRawText,
  });

  /// 수집한 거래 [incoming]을 저장하고, [cancelIds]의 원거래를 취소 처리한다.
  /// 모두 한 DB 트랜잭션이라 중간에 실패하면 전부 되돌리고 예외를 던진다.
  /// 원거래는 저장소의 현재 상태가 아직 취소 대상일 때만(decide의 `cancellableOriginal`과
  /// 같은 조건) 한 문장으로 바꾼다. [clearRawText]면 원문도 지운다.
  /// 실제로 취소된 id 집합을 돌려준다.
  Future<Set<String>> saveIncoming(
    Transaction incoming,
    List<String> cancelIds, {
    required bool clearRawText,
  });

  /// 사용자가 고친 금액·상대·일시·분류·상태를 반영한다.
  /// 취소·중복 거래는 바꾸지 않으며, 반영됐을 때만 true. [clearRawText]면 원문도 지운다.
  Future<bool> updateEditable(Transaction edited, {required bool clearRawText});
}
