import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../features/confirm_notification/domain/notification_text.dart';
import '../features/ingest/domain/ingest.dart';
import 'bootstrap.dart';
import 'spend_ledger_app.dart';

/// 확인 알림의 포함/제외 액션인지.
bool isConfirmAction(String? actionId) =>
    actionId == includeActionId || actionId == excludeActionId;

/// 앱이 떠 있지 않을 때 누른 포함/제외 액션. 별도 isolate에서 실행된다.
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse r) {
  if (!isConfirmAction(r.actionId) || r.payload == null) return;
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(handleNotificationAction(r, buildIngestDeps));
}

/// 앱이 떠 있을 때의 알림 응답. 액션이면 확정하고, 본문 탭이면 수정 화면을 연다.
void notificationForegroundHandler(NotificationResponse r) {
  final payload = r.payload;
  if (isConfirmAction(r.actionId)) {
    unawaited(handleNotificationAction(r, buildIngestDeps));
  } else if (r.actionId == null && payload != null) {
    openEditPage(payload);
  }
}

/// 포함/제외 액션이면 그 후보를 확정한다. 그 밖의 응답은 무시한다.
/// 알림 취소 실패 등 예외는 기록만 해 isolate가 죽지 않게 한다.
Future<void> handleNotificationAction(
  NotificationResponse r,
  Future<IngestDeps> Function() deps,
) async {
  final id = r.payload;
  if (!isConfirmAction(r.actionId) || id == null) return;
  try {
    await resolveCandidate(id, r.actionId == includeActionId, await deps());
  } catch (e, st) {
    debugPrint('resolveCandidate failed: $e\n$st');
  }
}
