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
  final payload = r.payload;
  if (!isConfirmAction(r.actionId) || payload == null) return;
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(_resolve(payload, r.actionId == includeActionId));
}

/// 앱이 떠 있을 때의 알림 응답. 액션이면 확정하고, 본문 탭이면 수정 화면을 연다.
void notificationForegroundHandler(NotificationResponse r) {
  final payload = r.payload;
  if (payload == null) return;
  if (isConfirmAction(r.actionId)) {
    unawaited(_resolve(payload, r.actionId == includeActionId));
  } else if (r.actionId == null) {
    openEditPage(payload);
  }
}

/// 알림 취소가 실패해도 isolate가 죽지 않도록 예외를 기록만 한다.
Future<void> _resolve(String id, bool include) async {
  try {
    await resolveCandidate(id, include, await buildIngestDeps());
  } catch (e, st) {
    debugPrint('resolveCandidate failed: $e\n$st');
  }
}
