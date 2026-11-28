import 'package:spend_ledger/features/ingest/domain/ingest.dart';
import 'package:spend_ledger/features/ledger/domain/ledger_repository.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';

/// 쓰기([upsertAll], [updateEditable])나 읽기([byStatus])를 실패시킬 수 있는 저장소.
class FailingLedger implements LedgerRepository {
  FailingLedger(this._inner);

  final LedgerRepository _inner;
  bool failWrites = false;
  bool failReads = false;

  Never _fail() => throw StateError('db failed');

  @override
  Future<void> upsertAll(List<Transaction> txs) =>
      failWrites ? _fail() : _inner.upsertAll(txs);

  @override
  Future<Transaction?> byId(String id) => _inner.byId(id);

  @override
  Future<List<Transaction>> since(DateTime from) => _inner.since(from);

  @override
  Future<List<Transaction>> byStatus(Set<TxStatus> statuses) =>
      failReads ? _fail() : _inner.byStatus(statuses);

  @override
  Future<bool> resolvePending(
    String id,
    TxStatus status, {
    required bool clearRawText,
  }) => failWrites
      ? _fail()
      : _inner.resolvePending(id, status, clearRawText: clearRawText);

  @override
  Future<Set<String>> saveIncoming(
    Transaction incoming,
    List<String> cancelIds, {
    required bool clearRawText,
  }) => failWrites
      ? _fail()
      : _inner.saveIncoming(incoming, cancelIds, clearRawText: clearRawText);

  @override
  Future<bool> updateEditable(
    Transaction edited, {
    required bool clearRawText,
  }) => failWrites
      ? _fail()
      : _inner.updateEditable(edited, clearRawText: clearRawText);
}

/// [d]의 저장소만 [ledger]로 바꾼 deps.
IngestDeps withLedger(IngestDeps d, LedgerRepository ledger) => IngestDeps(
  ledger: ledger,
  settings: d.settings,
  hints: d.hints,
  notifier: d.notifier,
  widgets: d.widgets,
  now: d.now,
  newId: d.newId,
);
