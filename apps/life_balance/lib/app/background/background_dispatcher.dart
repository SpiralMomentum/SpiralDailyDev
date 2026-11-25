import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/balance/domain/calendar_date.dart';
import '../../features/life_table/data/asset_life_table_repository.dart';
import '../../features/life_table/domain/life_table.dart';
import '../../features/ongoing_notification/data/midnight_scheduler.dart';
import '../../features/ongoing_notification/data/ongoing_notifier.dart';
import '../../features/profile/data/prefs_profile_repository.dart';
import '../../features/profile/domain/profile_repository.dart';
import '../../features/tone/data/asset_tone_repository.dart';
import '../../features/tone/domain/tone.dart';
import '../../features/tone/domain/tone_table.dart';
import '../../features/widget_sync/data/home_widget_sync.dart';

typedef LifeTableLoader = Future<LifeTable?> Function();
typedef ToneLoader = Future<ToneTable?> Function(ToneId id);

/// 백그라운드 작업 한 번에 필요한 입력과 부수효과 경계.
class BackgroundDeps {
  const BackgroundDeps({
    required this.profiles,
    required this.loadLifeTable,
    required this.loadTone,
    required this.widgets,
    required this.notifier,
    required this.scheduler,
    required this.now,
  });

  final ProfileRepository profiles;
  final LifeTableLoader loadLifeTable;
  final ToneLoader loadTone;
  final WidgetGateway widgets;
  final OngoingNotifier notifier;
  final RefreshScheduler scheduler;
  final DateTime Function() now;
}

/// 저장소에서 프로필/설정/생명표/말투를 읽어 위젯과 알림을 갱신한다.
/// `lb_midnight`이면 성공 여부와 관계없이 다음 자정 작업을 다시 예약한다.
/// 반환값 false는 WorkManager에 재시도를 요청한다.
Future<bool> runBackgroundTask(String task, BackgroundDeps deps) async {
  final now = deps.now();
  var ok = true;
  try {
    final profile = await deps.profiles.loadProfile();
    if (profile != null) {
      final settings = await deps.profiles.loadSettings();
      final table = await deps.loadLifeTable();
      final tone = await deps.loadTone(settings.tone);
      if (table != null && tone != null) {
        await syncDerivedOutputs(
          profile: profile,
          settings: settings,
          table: table,
          tone: tone,
          today: CalendarDate.fromDateTime(now),
          widgets: deps.widgets,
          notifier: deps.notifier,
        );
      }
    }
  } catch (_) {
    ok = false;
  }
  if (task == RefreshTasks.midnight) {
    try {
      await deps.scheduler.ensureScheduled(now, fromMidnightJob: true);
    } catch (_) {
      ok = false;
    }
  }
  return ok;
}

/// 백그라운드 isolate용 생명표 로더. 로드 실패 시 null을 돌려 동기화를 건너뛴다.
Future<LifeTable?> _loadLifeTableFromAssets() async =>
    (await AssetLifeTableRepository().load()).dataOrNull;

Future<ToneTable?> _loadToneFromAssets(ToneId id) async =>
    (await AssetToneRepository().load(id)).dataOrNull;

/// WorkManager 진입점. `Workmanager().initialize(backgroundDispatcher)`는 앱 bootstrap에서 호출한다.
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return runBackgroundTask(
      task,
      BackgroundDeps(
        profiles: PrefsProfileRepository(prefs),
        loadLifeTable: _loadLifeTableFromAssets,
        loadTone: _loadToneFromAssets,
        widgets: const HomeWidgetGateway(),
        notifier: LocalOngoingNotifier(),
        scheduler: WorkmanagerRefreshScheduler(),
        now: DateTime.now,
      ),
    );
  });
}
