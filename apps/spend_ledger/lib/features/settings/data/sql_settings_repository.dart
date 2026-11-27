import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';

import '../../budget/domain/budget_alert.dart';
import '../domain/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings s);
  Future<Set<BudgetAlert>> sentAlerts(String periodKey);
  Future<void> markSent(String periodKey, BudgetAlert a);
}

class SqlSettingsRepository implements SettingsRepository {
  const SqlSettingsRepository(this._db);

  final Database _db;

  static const _settingsKey = 'settings';
  static String _alertsKey(String periodKey) => 'alerts:$periodKey';

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
    final raw = await _read(_alertsKey(periodKey));
    if (raw == null) return {};
    return {
      for (final n in jsonDecode(raw) as List)
        BudgetAlert.values.byName(n as String),
    };
  }

  @override
  Future<void> markSent(String periodKey, BudgetAlert a) async {
    final sent = {...await sentAlerts(periodKey), a};
    await _write(
      _alertsKey(periodKey),
      jsonEncode([for (final s in sent) s.name]),
    );
  }
}
