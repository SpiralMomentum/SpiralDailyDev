import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/ongoing_notification/data/ongoing_notifier.dart';
import 'package:mocktail/mocktail.dart';

class MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class MockAndroid extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

void main() {
  late MockPlugin plugin;
  late MockAndroid android;

  setUpAll(() => registerFallbackValue(const InitializationSettings()));

  setUp(() {
    plugin = MockPlugin();
    android = MockAndroid();
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
        onDidReceiveBackgroundNotificationResponse: any(
          named: 'onDidReceiveBackgroundNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(android);
  });

  test('권한 허용이면 true', () async {
    when(
      () => android.requestNotificationsPermission(),
    ).thenAnswer((_) async => true);
    expect(
      await LocalOngoingNotifier(plugin: plugin).requestPermission(),
      isTrue,
    );
  });

  test('PlatformException은 false로 처리', () async {
    when(
      () => android.requestNotificationsPermission(),
    ).thenThrow(PlatformException(code: 'PERMISSION_REQUEST_IN_PROGRESS'));
    expect(
      await LocalOngoingNotifier(plugin: plugin).requestPermission(),
      isFalse,
    );
  });

  test('플러그인 구현이 없으면(null) false', () async {
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(null);
    expect(
      await LocalOngoingNotifier(plugin: plugin).requestPermission(),
      isFalse,
    );
  });

  test('초기화 실패는 캐시하지 않고 다음 호출에서 다시 시도한다', () async {
    var attempts = 0;
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
        onDidReceiveBackgroundNotificationResponse: any(
          named: 'onDidReceiveBackgroundNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async {
      if (attempts++ == 0) throw PlatformException(code: 'init');
      return true;
    });
    when(
      () => android.requestNotificationsPermission(),
    ).thenAnswer((_) async => true);
    final notifier = LocalOngoingNotifier(plugin: plugin);

    expect(await notifier.requestPermission(), isFalse);
    expect(await notifier.requestPermission(), isTrue);
    expect(attempts, 2);
    // 성공한 초기화는 다시 하지 않는다.
    expect(await notifier.requestPermission(), isTrue);
    expect(attempts, 2);
  });
}
