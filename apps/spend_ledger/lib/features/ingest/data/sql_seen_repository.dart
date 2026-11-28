import 'package:sqflite_common/sqlite_api.dart';

import '../domain/seen_repository.dart';

class SqlSeenRepository implements SeenRepository {
  const SqlSeenRepository(this._db);

  final Database _db;

  @override
  Future<bool> claim(String fingerprint, DateTime at, Duration window) =>
      _db.transaction((txn) async {
        final atMs = at.millisecondsSinceEpoch;
        await txn.delete(
          'seen_notifications',
          where: 'at < ?',
          whereArgs: [atMs - window.inMilliseconds],
        );
        // 한 문장으로 판정해 동시에 들어온 같은 알림도 한 번만 true.
        final inserted = await txn.rawUpdate(
          'INSERT OR IGNORE INTO seen_notifications(fingerprint, at) '
          'VALUES(?, ?)',
          [fingerprint, atMs],
        );
        return inserted == 1;
      });

  @override
  Future<void> release(String fingerprint) => _db.delete(
    'seen_notifications',
    where: 'fingerprint = ?',
    whereArgs: [fingerprint],
  );
}
