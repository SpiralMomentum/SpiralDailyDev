import 'package:workmanager/workmanager.dart';

import '../domain/midnight.dart';

/// WorkManager 작업 이름. uniqueName과 taskName을 같게 쓴다.
abstract final class RefreshTasks {
  static const midnight = 'lb_midnight';
  static const hourly = 'lb_hourly';
}

abstract interface class RefreshScheduler {
  /// [fromMidnightJob]은 실행 중인 `lb_midnight` 작업 안에서 다음 자정을 예약할 때 true.
  Future<void> ensureScheduled(DateTime now, {bool fromMidnightJob = false});
}

/// 다음 자정 + 1분 one-off 작업과, 재부팅/작업 유실 복구용 1시간 주기 작업을 예약한다.
class WorkmanagerRefreshScheduler implements RefreshScheduler {
  WorkmanagerRefreshScheduler([Workmanager? workmanager])
      : _wm = workmanager ?? Workmanager();

  final Workmanager _wm;

  @override
  Future<void> ensureScheduled(
    DateTime now, {
    bool fromMidnightJob = false,
  }) async {
    await _wm.registerOneOffTask(
      RefreshTasks.midnight,
      RefreshTasks.midnight,
      initialDelay: delayUntilNextRefresh(now),
      // 실행 중인 자기 자신을 replace하면 현재 작업이 취소된다. 작업 안에서는
      // append(네이티브 APPEND_OR_REPLACE)로 현재 작업 뒤에 잇는다.
      existingWorkPolicy: fromMidnightJob
          ? ExistingWorkPolicy.append
          : ExistingWorkPolicy.replace,
    );
    await _wm.registerPeriodicTask(
      RefreshTasks.hourly,
      RefreshTasks.hourly,
      frequency: const Duration(hours: 1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}
