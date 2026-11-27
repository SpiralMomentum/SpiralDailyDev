import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../features/budget/domain/budget_alert.dart';
import '../features/budget/domain/summary.dart';
import '../features/confirm_notification/domain/notification_text.dart';
import '../features/ingest/data/ios_bridge.dart';
import '../features/ingest/domain/ingest.dart';
import '../features/ledger/domain/transaction.dart';
import '../features/message_filter/domain/raw_message.dart';
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

/// 헤드리스 엔진과 Swift `HeadlessIngest` 사이의 채널.
const MethodChannel ingestChannel = MethodChannel('spend_ledger/ingest');

/// iOS 단축어 App Intent가 띄우는 헤드리스 엔진의 진입점.
/// 의존성을 미리 만들고 핸들러를 등록한 뒤 `ready`로 Swift에 준비를 알린다.
/// 의존성 생성에 실패해도 준비 신호는 보내, 호출마다 오류 결과로 빨리 답하게 한다.
@pragma('vm:entry-point')
Future<void> iosIngestMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    await buildIngestDeps();
  } catch (e, st) {
    debugPrint('buildIngestDeps failed: $e\n$st');
  }
  ingestChannel.setMethodCallHandler(_onIngestCall);
  await ingestChannel.invokeMethod<void>('ready');
}

Future<Map<String, Object?>> _onIngestCall(MethodCall call) async {
  final watch = Stopwatch()..start();
  final IngestDeps deps;
  try {
    deps = await buildIngestDeps();
  } catch (e) {
    return {
      'result': 'error',
      'error': '$e',
      'dartMs': watch.elapsedMilliseconds,
    };
  }
  return handleIngestCall(call, deps);
}

/// `ingest` 호출 `{text, sender?}`을 단축어 문자로 저장하고 결과를 돌려준다.
/// `{result: filtered|stored|error, txId?, notified, dartMs, error?}`
/// 처리 중 예외는 던지지 않고 `error` 결과로 알린다.
Future<Map<String, Object?>> handleIngestCall(
  MethodCall call,
  IngestDeps deps,
) async {
  if (call.method != 'ingest') {
    throw MissingPluginException('unsupported method ${call.method}');
  }
  final watch = Stopwatch()..start();
  final notifier = _AskRecorder(deps.notifier);
  try {
    final args = call.arguments as Map<Object?, Object?>;
    final (result, tx) = await ingestMessage(
      RawMessage(
        text: args['text']! as String,
        sender: args['sender'] as String?,
        receivedAt: deps.now(),
        source: MessageSource.iosShortcut,
      ),
      _withNotifier(deps, notifier),
    );
    return {
      'result': result.name,
      if (tx != null) 'txId': tx.id,
      'notified': notifier.asked,
      'dartMs': watch.elapsedMilliseconds,
    };
  } catch (e, st) {
    debugPrint('ingest call failed: $e\n$st');
    return {
      'result': 'error',
      'error': '$e',
      'notified': notifier.asked,
      'dartMs': watch.elapsedMilliseconds,
    };
  }
}

/// iOS 대체 경로가 쌓아 둔 원문을 꺼내 단축어 문자로 저장한다.
/// 채널이 없는 플랫폼(Android)에서는 아무것도 하지 않는다.
/// 꺼낸 뒤 한 건이 실패해도 나머지는 계속 처리한다.
Future<void> drainIosInbox(
  IngestDeps deps, {
  MethodChannel channel = iosDiagnosticsChannel,
}) async {
  final List<String> texts;
  try {
    texts = await channel.invokeListMethod<String>('drainInbox') ?? const [];
  } on MissingPluginException {
    return;
  } catch (e, st) {
    debugPrint('drainInbox failed: $e\n$st');
    return;
  }
  for (final text in texts) {
    try {
      await ingestMessage(
        RawMessage(
          text: text,
          receivedAt: deps.now(),
          source: MessageSource.iosShortcut,
        ),
        deps,
      );
    } catch (e, st) {
      debugPrint('inbox ingest failed: $e\n$st');
    }
  }
}

IngestDeps _withNotifier(IngestDeps d, ConfirmNotifier notifier) => IngestDeps(
  ledger: d.ledger,
  settings: d.settings,
  hints: d.hints,
  notifier: notifier,
  widgets: d.widgets,
  now: d.now,
  newId: d.newId,
);

/// 확인 알림을 요청했는지 기록한다.
class _AskRecorder implements ConfirmNotifier {
  _AskRecorder(this._inner);

  final ConfirmNotifier _inner;
  bool asked = false;

  @override
  Future<void> askConfirm(Transaction tx) {
    asked = true;
    return _inner.askConfirm(tx);
  }

  @override
  Future<void> budgetAlert(BudgetAlert alert, LedgerSummary s) =>
      _inner.budgetAlert(alert, s);

  @override
  Future<void> cancel(String txId) => _inner.cancel(txId);
}
