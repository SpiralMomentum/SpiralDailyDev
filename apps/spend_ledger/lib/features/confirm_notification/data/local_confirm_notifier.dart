import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../budget/domain/budget_alert.dart';
import '../../budget/domain/summary.dart';
import '../../ingest/domain/ingest.dart';
import '../../ledger/domain/transaction.dart';
import '../domain/notification_id.dart';
import '../domain/notification_text.dart';

const AndroidNotificationChannel _confirmChannel = AndroidNotificationChannel(
  confirmCategoryId,
  '지출 확인',
  importance: Importance.high,
);

const AndroidNotificationChannel _budgetChannel = AndroidNotificationChannel(
  budgetChannelId,
  '예산 알림',
);

/// 포함/제외 액션. 둘 다 앱을 열지 않고 백그라운드 처리기로 응답한다.
final DarwinNotificationCategory _confirmCategory = DarwinNotificationCategory(
  confirmCategoryId,
  actions: [
    DarwinNotificationAction.plain(includeActionId, includeActionLabel),
    DarwinNotificationAction.plain(excludeActionId, excludeActionLabel),
  ],
);

const List<AndroidNotificationAction> _androidActions = [
  AndroidNotificationAction(
    includeActionId,
    includeActionLabel,
    showsUserInterface: false,
  ),
  AndroidNotificationAction(
    excludeActionId,
    excludeActionLabel,
    showsUserInterface: false,
  ),
];

/// 알림 채널·카테고리를 등록하고 플러그인을 초기화한다.
Future<void> initNotifications(
  FlutterLocalNotificationsPlugin p, {
  required void Function(NotificationResponse) onForeground,
  required void Function(NotificationResponse) onBackground,
}) async {
  final android = p
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await android?.createNotificationChannel(_confirmChannel);
  await android?.createNotificationChannel(_budgetChannel);
  await p.initialize(
    settings: InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      // 권한은 메인 앱 시작 시 따로 요청한다(백그라운드 isolate에서 묻지 않도록).
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [_confirmCategory],
      ),
    ),
    onDidReceiveNotificationResponse: onForeground,
    onDidReceiveBackgroundNotificationResponse: onBackground,
  );
}

/// [ConfirmNotifier]의 로컬 알림 구현. 문구는 domain의 순수 함수에서 만든다.
class LocalConfirmNotifier implements ConfirmNotifier {
  const LocalConfirmNotifier(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> askConfirm(Transaction tx) => _plugin.show(
    id: notificationIdFor(tx.id),
    body: confirmBody(tx),
    payload: tx.id,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _confirmChannel.id,
        _confirmChannel.name,
        importance: Importance.high,
        priority: Priority.high,
        actions: _androidActions,
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: confirmCategoryId,
      ),
    ),
  );

  @override
  Future<void> budgetAlert(BudgetAlert alert, LedgerSummary s) => _plugin.show(
    id: notificationIdFor(budgetNotificationKey(alert.name)),
    body: budgetAlertBody(alert, s),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _budgetChannel.id,
        _budgetChannel.name,
      ),
      iOS: const DarwinNotificationDetails(),
    ),
  );

  @override
  Future<void> cancel(String txId) =>
      _plugin.cancel(id: notificationIdFor(txId));
}
