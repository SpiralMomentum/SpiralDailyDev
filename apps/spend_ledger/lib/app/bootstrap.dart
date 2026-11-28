import 'dart:io' show File;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite_sqlcipher/sqflite.dart' show getDatabasesPath;

import '../features/confirm_notification/data/local_confirm_notifier.dart';
import '../features/ingest/data/android_bridge.dart';
import '../features/ingest/data/sql_seen_repository.dart';
import '../features/ingest/domain/ingest.dart';
import '../features/ledger/data/db_key.dart';
import '../features/ledger/data/ledger_database.dart';
import '../features/ledger/data/sql_ledger_repository.dart';
import '../features/parsing/data/sql_format_hint_repository.dart';
import '../features/settings/data/sql_settings_repository.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/widget_sync/data/home_widget_gateway.dart';
import 'ingest_entry.dart';

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

Future<IngestDeps>? _deps;

/// 키 로드, DB 열기, 알림 초기화, 리포지토리 조립.
/// 메인 앱·백그라운드 처리기·헤드리스 엔진이 함께 쓰며, isolate마다 한 번만 만든다.
/// 실패하면 다음 호출에서 다시 시도한다.
Future<IngestDeps> buildIngestDeps() =>
    _deps ??= _build().catchError((Object e, StackTrace st) {
      _deps = null;
      return Future<IngestDeps>.error(e, st);
    });

Future<IngestDeps> _build() async {
  final path = join(await getDatabasesPath(), 'ledger.db');
  final key = await loadOrCreateDbKey(
    const SecureKeyStore(),
    Random.secure(),
    databaseExists: File(path).existsSync(),
  );
  final db = await openLedgerDatabase(path, key);
  await initNotifications(
    _notifications,
    onForeground: notificationForegroundHandler,
    onBackground: notificationBackgroundHandler,
  );
  final random = Random.secure();
  return IngestDeps(
    ledger: SqlLedgerRepository(db),
    settings: SqlSettingsRepository(db),
    hints: SqlFormatHintRepository(db),
    seen: SqlSeenRepository(db),
    notifier: LocalConfirmNotifier(_notifications),
    widgets: defaultTargetPlatform == TargetPlatform.android
        ? HomeWidgetGateway()
        : const NoopWidgetGateway(),
    now: DateTime.now,
    newId: () =>
        '${DateTime.now().microsecondsSinceEpoch}-'
        '${random.nextInt(1 << 32).toRadixString(16)}',
  );
}

/// 메인 앱 시작 준비. 알림 권한을 요청하고, iOS 대체 경로 수신함을 비워 저장하며,
/// 알림 본문을 눌러 시작됐다면 열어야 할 거래 id를 함께 돌려준다.
Future<(IngestDeps, String?, AppSettings)> bootstrap() async {
  final deps = await buildIngestDeps();
  await _requestNotificationPermission();
  await drainIosInbox(deps);
  await _syncAllowedPackages(deps);
  return (deps, await _launchEditId(), await _loadSettings(deps));
}

Future<void> _requestNotificationPermission() async {
  try {
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  } catch (e) {
    debugPrint('notification permission request failed: ${e.runtimeType}');
  }
}

/// 첫 프레임에 쓸 설정. 읽기에 실패하면 기본값으로 시작한다.
Future<AppSettings> _loadSettings(IngestDeps deps) async {
  try {
    return await deps.settings.load();
  } catch (e) {
    debugPrint('initial settings load failed: ${e.runtimeType}');
    return const AppSettings();
  }
}

Future<String?> _launchEditId() async {
  final details = await _notifications.getNotificationAppLaunchDetails();
  final response = details?.notificationResponse;
  if (details?.didNotificationLaunchApp != true || response == null) {
    return null;
  }
  return isConfirmAction(response.actionId) ? null : response.payload;
}

/// Android 리스너가 쓸 허용 앱 목록을 네이티브에 맞춘다. 실패는 기록만 한다.
Future<void> _syncAllowedPackages(IngestDeps deps) async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  try {
    final settings = await deps.settings.load();
    await const AndroidBridge().setAllowedPackages(
      settings.notificationPackages,
    );
  } catch (e) {
    debugPrint('setAllowedPackages failed: ${e.runtimeType}');
  }
}
