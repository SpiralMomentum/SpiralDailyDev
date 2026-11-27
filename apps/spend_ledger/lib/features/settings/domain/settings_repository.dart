import '../../budget/domain/budget_alert.dart';
import 'app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings s);
  Future<Set<BudgetAlert>> sentAlerts(String periodKey);

  /// 알림을 보냄으로 표시한다. 이번 호출로 처음 표시됐을 때만 true.
  Future<bool> markSent(String periodKey, BudgetAlert a);
}
