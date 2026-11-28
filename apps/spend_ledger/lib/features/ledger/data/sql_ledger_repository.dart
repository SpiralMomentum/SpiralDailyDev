import 'package:sqflite_common/sqlite_api.dart' hide Transaction;

import '../../parsing/domain/parsed_message.dart';
import '../domain/ledger_repository.dart';
import '../domain/transaction.dart';

class SqlLedgerRepository implements LedgerRepository {
  const SqlLedgerRepository(this._db);

  final Database _db;

  @override
  Future<void> upsertAll(List<Transaction> txs) async {
    final batch = _db.batch();
    for (final t in txs) {
      batch.insert(
        'transactions',
        _toRow(t),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<Transaction?> byId(String id) async {
    final rows = await _db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<List<Transaction>> since(DateTime from) async {
    final rows = await _db.query(
      'transactions',
      where: 'occurredAt >= ?',
      whereArgs: [from.millisecondsSinceEpoch],
      orderBy: 'occurredAt ASC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<Transaction>> byStatus(Set<TxStatus> statuses) async {
    if (statuses.isEmpty) return const [];
    final marks = List.filled(statuses.length, '?').join(',');
    final rows = await _db.query(
      'transactions',
      where: 'status IN ($marks)',
      whereArgs: [for (final s in statuses) s.name],
      orderBy: 'occurredAt DESC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<bool> resolvePending(
    String id,
    TxStatus status, {
    required bool clearRawText,
  }) async {
    final count = await _db.rawUpdate(
      'UPDATE transactions SET status = ?'
      '${clearRawText ? ', rawText = NULL' : ''}'
      ' WHERE id = ? AND status = ?',
      [status.name, id, TxStatus.pending.name],
    );
    return count == 1;
  }

  /// 취소 조건은 decide의 `cancellableOriginal`과 같다: 확인 필요·분류 불명이 아니고,
  /// 대기·포함이거나 취소·중복이 아닌 선불 사용.
  @override
  Future<Set<String>> saveIncoming(
    Transaction incoming,
    List<String> cancelIds, {
    required bool clearRawText,
  }) => _db.transaction((txn) async {
    await txn.insert(
      'transactions',
      _toRow(incoming),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    final cancelled = <String>{};
    for (final id in cancelIds) {
      final count = await txn.rawUpdate(
        'UPDATE transactions SET status = ?'
        '${clearRawText ? ', rawText = NULL' : ''}'
        ' WHERE id = ? AND needsReview = 0 AND category != ?'
        ' AND (status IN (?, ?) OR (category = ? AND status NOT IN (?, ?)))',
        [
          TxStatus.cancelled.name,
          id,
          SpendCategory.unknown.name,
          TxStatus.pending.name,
          TxStatus.included.name,
          SpendCategory.prepaidUse.name,
          TxStatus.cancelled.name,
          TxStatus.duplicate.name,
        ],
      );
      if (count == 1) cancelled.add(id);
    }
    return cancelled;
  });

  @override
  Future<bool> updateEditable(
    Transaction edited, {
    required bool clearRawText,
  }) async {
    final count = await _db.rawUpdate(
      'UPDATE transactions SET amount = ?, counterparty = ?, occurredAt = ?,'
      ' category = ?, status = ?'
      '${clearRawText ? ', rawText = NULL' : ''}'
      ' WHERE id = ? AND status IN (?, ?, ?)',
      [
        edited.amount,
        edited.counterparty,
        edited.occurredAt.millisecondsSinceEpoch,
        edited.category.name,
        edited.status.name,
        edited.id,
        for (final s in _editableStatuses) s.name,
      ],
    );
    return count == 1;
  }
}

const List<TxStatus> _editableStatuses = [
  TxStatus.pending,
  TxStatus.included,
  TxStatus.excluded,
];

Map<String, Object?> _toRow(Transaction t) => {
  'id': t.id,
  'amount': t.amount,
  'counterparty': t.counterparty,
  'occurredAt': t.occurredAt.millisecondsSinceEpoch,
  'receivedAt': t.receivedAt.millisecondsSinceEpoch,
  'kind': t.kind.name,
  'category': t.category.name,
  'status': t.status.name,
  'linkedId': t.linkedId,
  'rawText': t.rawText,
  'sender': t.sender,
  'needsReview': t.needsReview ? 1 : 0,
  'signature': t.signature,
};

Transaction _fromRow(Map<String, Object?> r) => Transaction(
  id: r['id']! as String,
  amount: r['amount']! as int,
  counterparty: r['counterparty']! as String,
  occurredAt: DateTime.fromMillisecondsSinceEpoch(r['occurredAt']! as int),
  receivedAt: DateTime.fromMillisecondsSinceEpoch(r['receivedAt']! as int),
  kind: MessageKind.values.byName(r['kind']! as String),
  category: SpendCategory.values.byName(r['category']! as String),
  status: TxStatus.values.byName(r['status']! as String),
  linkedId: r['linkedId'] as String?,
  rawText: r['rawText'] as String?,
  sender: r['sender'] as String?,
  needsReview: (r['needsReview']! as int) == 1,
  signature: r['signature']! as String,
);
