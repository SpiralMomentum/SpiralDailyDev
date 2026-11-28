import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../features/budget/domain/budget_alert.dart';
import '../features/budget/domain/summary.dart';
import '../features/confirm_notification/domain/notification_text.dart';
import '../features/ingest/data/ios_bridge.dart';
import '../features/ingest/domain/android_sources.dart';
import '../features/ingest/domain/ingest.dart';
import '../features/ledger/domain/ledger_repository.dart';
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
  } catch (e) {
    debugPrint('resolveCandidate failed: ${e.runtimeType}');
  }
}

/// 헤드리스 엔진과 Swift `HeadlessIngest` 사이의 채널.
const MethodChannel ingestChannel = MethodChannel('spend_ledger/ingest');

/// iOS 단축어 App Intent가 띄우는 헤드리스 엔진의 진입점.
/// 의존성을 미리 만들고 핸들러를 등록한 뒤 `ready`로 Swift에 준비를 알린다.
/// 의존성 생성에 실패해도 준비 신호는 보내, 호출마다 오류 결과로 빨리 답하게 한다.
@pragma('vm:entry-point')
Future<void> iosIngestMain() => _ingestMain();

/// Android 알림 리스너 서비스가 띄우는 헤드리스 엔진의 진입점. iOS와 같은 동작이다.
@pragma('vm:entry-point')
Future<void> androidIngestMain() => _ingestMain();

Future<void> _ingestMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    await buildIngestDeps();
  } catch (e) {
    debugPrint('buildIngestDeps failed: ${e.runtimeType}');
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
    debugPrint('buildIngestDeps failed: ${e.runtimeType}');
    return {
      'result': 'error',
      'error': _errorType(e),
      'notified': false,
      'dartMs': watch.elapsedMilliseconds,
    };
  }
  return handleIngestCall(call, deps);
}

/// `ingest` 호출 `{text, sender?, package?, postedAtMs?}`을 저장하고 결과를 돌려준다.
/// `{result: filtered|stored|seen|error, txId?, notified, notifyError?, error?, dartMs}`
/// `package`가 있으면(Android) 같은 `(패키지, 원문)`이 10분 안에 다시 오면 `seen`으로
/// 저장하지 않고, 저장 전에 실패하면 기록을 풀어 다음 재게시 때 다시 처리한다.
/// `refresh`는 요약·위젯을 다시 계산한다 `{result: refreshed|error, error?, dartMs}`.
/// 예외는 던지지 않는다. 저장 뒤의 실패(알림 등)는 `stored`에 `notifyError`로,
/// 저장 전의 실패만 `error`로 알린다. Swift는 `error`일 때만 대체 경로로 간다.
/// 오류는 원문이 섞이지 않도록 예외 타입 이름만 담는다.
Future<Map<String, Object?>> handleIngestCall(
  MethodCall call,
  IngestDeps deps,
) async {
  switch (call.method) {
    case 'ingest':
      return _handleIngest(call, deps);
    case 'refresh':
      return _handleRefresh(deps);
    default:
      throw MissingPluginException('unsupported method ${call.method}');
  }
}

const Duration _seenWindow = Duration(minutes: 10);

Future<Map<String, Object?>> _handleRefresh(IngestDeps deps) async {
  final watch = Stopwatch()..start();
  try {
    await refreshOutputs(deps);
    return {'result': 'refreshed', 'dartMs': watch.elapsedMilliseconds};
  } catch (e) {
    debugPrint('refresh failed: ${e.runtimeType}');
    return {
      'result': 'error',
      'error': _errorType(e),
      'dartMs': watch.elapsedMilliseconds,
    };
  }
}

Future<Map<String, Object?>> _handleIngest(
  MethodCall call,
  IngestDeps deps,
) async {
  final watch = Stopwatch()..start();
  final RawMessage raw;
  final String? package;
  try {
    final args = call.arguments as Map<Object?, Object?>;
    package = args['package'] as String?;
    final postedAtMs = args['postedAtMs'] as num?;
    raw = RawMessage(
      text: args['text']! as String,
      sender: args['sender'] as String?,
      receivedAt: postedAtMs == null
          ? deps.now()
          : DateTime.fromMillisecondsSinceEpoch(postedAtMs.toInt()),
      source: sourceForPackage(package),
    );
  } catch (e) {
    debugPrint('bad ingest call: ${e.runtimeType}');
    return {
      'result': 'error',
      'error': _errorType(e),
      'notified': false,
      'dartMs': watch.elapsedMilliseconds,
    };
  }
  String? fingerprint;
  if (package != null) {
    fingerprint = notificationFingerprint(package, raw.text);
    try {
      if (!await deps.seen.claim(fingerprint, raw.receivedAt, _seenWindow)) {
        return {
          'result': 'seen',
          'notified': false,
          'dartMs': watch.elapsedMilliseconds,
        };
      }
    } catch (e) {
      debugPrint('seen claim failed: ${e.runtimeType}');
      return {
        'result': 'error',
        'error': _errorType(e),
        'notified': false,
        'dartMs': watch.elapsedMilliseconds,
      };
    }
  }
  final report = await _ingestReport(raw, deps);
  if (fingerprint != null && report['result'] == 'error') {
    try {
      await deps.seen.release(fingerprint);
    } catch (e) {
      debugPrint('seen release failed: ${e.runtimeType}');
    }
  }
  return {...report, 'dartMs': watch.elapsedMilliseconds};
}

/// iOS 대체 경로가 쌓아 둔 문자를 받은 시각·보낸 사람 그대로 저장한다.
/// 저장(또는 필터)된 항목만 `ackInbox`로 알려 지우게 하고, 실패한 항목은 남겨 다음에 다시 한다.
/// 채널이 없는 플랫폼(Android)에서는 아무것도 하지 않는다.
Future<void> drainIosInbox(
  IngestDeps deps, {
  MethodChannel channel = iosDiagnosticsChannel,
}) async {
  final List<Object?> entries;
  try {
    entries = await channel.invokeListMethod<Object?>('drainInbox') ?? const [];
  } on MissingPluginException {
    return;
  } catch (e) {
    debugPrint('drainInbox failed: ${e.runtimeType}');
    return;
  }
  final acked = <String>[];
  for (final entry in entries) {
    final InboxItem item;
    try {
      item = InboxItem.fromMap(entry! as Map<Object?, Object?>);
    } catch (e) {
      debugPrint('bad inbox item: ${e.runtimeType}');
      continue;
    }
    final report = await _ingestReport(item.toRawMessage(), deps);
    if (report['result'] != 'error') acked.add(item.id);
  }
  if (acked.isEmpty) return;
  try {
    await channel.invokeMethod<void>('ackInbox', {'ids': acked});
  } catch (e) {
    debugPrint('ackInbox failed: ${e.runtimeType}');
  }
}

/// 한 건을 저장하고 결과를 맵으로 돌려준다. 예외는 던지지 않는다.
/// 저장소에 이번 거래가 써진 뒤의 예외는 저장 성공으로 본다.
Future<Map<String, Object?>> _ingestReport(
  RawMessage raw,
  IngestDeps deps,
) async {
  final notifier = _AskRecorder(deps.notifier);
  final ledger = _UpsertRecorder(deps.ledger);
  String? incomingId;
  final tracked = IngestDeps(
    ledger: ledger,
    settings: deps.settings,
    hints: deps.hints,
    seen: deps.seen,
    notifier: notifier,
    widgets: deps.widgets,
    now: deps.now,
    newId: () => incomingId = deps.newId(),
  );
  try {
    final (result, tx) = await ingestMessage(raw, tracked);
    return {
      'result': result.name,
      if (tx != null) 'txId': tx.id,
      'notified': notifier.asked,
    };
  } catch (e) {
    debugPrint('ingest failed: ${e.runtimeType}');
    final id = incomingId;
    if (id != null && ledger.upserted.contains(id)) {
      return {
        'result': IngestResult.stored.name,
        'txId': id,
        'notified': false,
        'notifyError': _errorType(e),
      };
    }
    return {'result': 'error', 'error': _errorType(e), 'notified': false};
  }
}

String _errorType(Object e) => '${e.runtimeType}';

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

/// 실제로 써진 거래 id를 기록한다.
class _UpsertRecorder implements LedgerRepository {
  _UpsertRecorder(this._inner);

  final LedgerRepository _inner;
  final Set<String> upserted = {};

  @override
  Future<void> upsertAll(List<Transaction> txs) async {
    await _inner.upsertAll(txs);
    upserted.addAll(txs.map((t) => t.id));
  }

  @override
  Future<Transaction?> byId(String id) => _inner.byId(id);

  @override
  Future<List<Transaction>> since(DateTime from) => _inner.since(from);

  @override
  Future<List<Transaction>> byStatus(Set<TxStatus> statuses) =>
      _inner.byStatus(statuses);

  @override
  Future<bool> resolvePending(
    String id,
    TxStatus status, {
    required bool clearRawText,
  }) => _inner.resolvePending(id, status, clearRawText: clearRawText);

  @override
  Future<Set<String>> saveIncoming(
    Transaction incoming,
    List<String> cancelIds, {
    required bool clearRawText,
  }) async {
    final cancelled = await _inner.saveIncoming(
      incoming,
      cancelIds,
      clearRawText: clearRawText,
    );
    upserted.add(incoming.id);
    return cancelled;
  }

  @override
  Future<bool> updateEditable(
    Transaction edited, {
    required bool clearRawText,
  }) => _inner.updateEditable(edited, clearRawText: clearRawText);
}
