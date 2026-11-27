import 'package:sqflite_common/sqlite_api.dart' hide Transaction;

import '../../parsing/domain/parsed_message.dart';
import '../domain/transaction.dart';

abstract interface class LedgerRepository {
  Future<void> upsertAll(List<Transaction> txs);
  Future<Transaction?> byId(String id);
  Future<List<Transaction>> since(DateTime from);
  Future<List<Transaction>> byStatus(Set<TxStatus> statuses);
}

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
}

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
