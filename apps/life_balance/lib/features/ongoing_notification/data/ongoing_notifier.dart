import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract interface class OngoingNotifier {
  /// Android 13+ 알림 권한 요청. 허용되면 true.
  Future<bool> requestPermission();
  Future<void> show(String text);
  Future<void> cancel();
}

/// 잔고 상시 알림. 낮은 중요도 채널(소리/진동 없음), 밀어도 지워지지 않는 ongoing.
class LocalOngoingNotifier implements OngoingNotifier {
  LocalOngoingNotifier({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const channelId = 'lb_balance';
  static const channelName = '인생잔고';
  static const notificationId = 1;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      showWhen: false,
    ),
  );

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialized;

  /// 백그라운드 isolate에서도 호출되므로 처음 쓸 때 한 번 초기화한다.
  /// 실패하면 캐시를 비워 다음 호출에서 다시 시도한다.
  Future<void> _ensureInitialized() => _initialized ??= _plugin
      .initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      )
      .then<void>(
        (_) {},
        onError: (Object e, StackTrace st) {
          _initialized = null;
          Error.throwWithStackTrace(e, st);
        },
      );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> requestPermission() async {
    try {
      await _ensureInitialized();
      return await _android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      // PERMISSION_REQUEST_IN_PROGRESS, 액티비티 없음 등은 거부로 취급한다.
      return false;
    }
  }

  @override
  Future<void> show(String text) async {
    await _ensureInitialized();
    await _plugin.show(
      id: notificationId,
      title: channelName,
      body: text,
      notificationDetails: _details,
    );
  }

  @override
  Future<void> cancel() async {
    await _ensureInitialized();
    await _plugin.cancel(id: notificationId);
  }
}
