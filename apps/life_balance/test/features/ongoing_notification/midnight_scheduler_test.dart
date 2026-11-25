import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/ongoing_notification/data/midnight_scheduler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workmanager/workmanager.dart';

class _MockWorkmanager extends Mock implements Workmanager {}

void main() {
  test('one-off lb_midnight(replace, 자정+1분) + periodic lb_hourly(1시간, keep)',
      () async {
    final wm = _MockWorkmanager();
    when(() => wm.registerOneOffTask(any(), any(),
            initialDelay: any(named: 'initialDelay'),
            existingWorkPolicy: any(named: 'existingWorkPolicy')))
        .thenAnswer((_) async {});
    when(() => wm.registerPeriodicTask(any(), any(),
            frequency: any(named: 'frequency'),
            existingWorkPolicy: any(named: 'existingWorkPolicy')))
        .thenAnswer((_) async {});

    await WorkmanagerRefreshScheduler(wm)
        .ensureScheduled(DateTime(2026, 11, 25, 23, 0));

    verify(() => wm.registerOneOffTask(
          RefreshTasks.midnight,
          RefreshTasks.midnight,
          initialDelay: const Duration(hours: 1, minutes: 1),
          existingWorkPolicy: ExistingWorkPolicy.replace,
        )).called(1);
    verify(() => wm.registerPeriodicTask(
          RefreshTasks.hourly,
          RefreshTasks.hourly,
          frequency: const Duration(hours: 1),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        )).called(1);
    expect(RefreshTasks.midnight, 'lb_midnight');
    expect(RefreshTasks.hourly, 'lb_hourly');
  });

  test('실행 중인 lb_midnight 안에서 재예약하면 append(자기 취소 방지)', () async {
    final wm = _MockWorkmanager();
    when(() => wm.registerOneOffTask(any(), any(),
            initialDelay: any(named: 'initialDelay'),
            existingWorkPolicy: any(named: 'existingWorkPolicy')))
        .thenAnswer((_) async {});
    when(() => wm.registerPeriodicTask(any(), any(),
            frequency: any(named: 'frequency'),
            existingWorkPolicy: any(named: 'existingWorkPolicy')))
        .thenAnswer((_) async {});

    await WorkmanagerRefreshScheduler(wm).ensureScheduled(
      DateTime(2026, 11, 26, 0, 1),
      fromMidnightJob: true,
    );

    verify(() => wm.registerOneOffTask(
          RefreshTasks.midnight,
          RefreshTasks.midnight,
          initialDelay: const Duration(days: 1),
          existingWorkPolicy: ExistingWorkPolicy.append,
        )).called(1);
  });
}
