import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';

import '../../budget/domain/budget_alert.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class SqlSettingsRepository implements SettingsRepository {
  const SqlSettingsRepository(this._db);

  final Database _db;

  static const _settingsKey = 'settings';
  static String _alertsPrefix(String periodKey) => 'alerts:$periodKey:';

  Future<String?> _read(String key) async {
    final rows = await _db.query('kv', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value']! as String;
  }

  Future<void> _write(String key, String value) => _db.insert('kv', {
    'key': key,
    'value': value,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<AppSettings> load() async {
    final raw = await _read(_settingsKey);
    if (raw == null) return const AppSettings();
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(AppSettings s) =>
      _write(_settingsKey, jsonEncode(s.toJson()));

  @override
  Future<Set<BudgetAlert>> sentAlerts(String periodKey) async {
    final prefix = _alertsPrefix(periodKey);
    final rows = await _db.query(
      'kv',
      columns: ['key'],
      where: 'substr(key, 1, ?) = ?',
      whereArgs: [prefix.length, prefix],
    );
    final names = {for (final a in BudgetAlert.values) a.name: a};
    return {
      for (final r in rows)
        ?names[(r['key']! as String).substring(prefix.length)],
    };
  }

  /// 알림마다 한 행. `INSERT OR IGNORE`와 `changes()`를 한 트랜잭션에서 실행해
  /// 동시에 두 번 호출돼도 한쪽만 true를 받는다.
  @override
  Future<bool> markSent(String periodKey, BudgetAlert a) =>
      _db.transaction((txn) async {
        await txn.rawInsert(
          'INSERT OR IGNORE INTO kv(key, value) VALUES(?, ?)',
          ['${_alertsPrefix(periodKey)}${a.name}', '1'],
        );
        final rows = await txn.rawQuery('SELECT changes() AS c');
        return rows.first['c'] == 1;
      });
}
