import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/app/ingest_entry.dart';
import 'package:spend_ledger/features/ingest/data/ios_bridge.dart';
import 'package:spend_ledger/features/ingest/domain/ingest.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';

import 'package:spend_ledger/features/ledger/domain/ledger_repository.dart';

import '../fixtures/messages.dart';
import '../support/failing_ledger.dart';
import '../support/fakes.dart';

NotificationResponse _response({String? actionId, String? payload}) =>
    NotificationResponse(
      notificationResponseType: actionId == null
          ? NotificationResponseType.selectedNotification
          : NotificationResponseType.selectedNotificationAction,
      actionId: actionId,
      payload: payload,
    );

void main() {
  group('handleNotificationAction', _notificationActionTests);
  group('handleIngestCall', _ingestCallTests);
  group('drainIosInbox', _drainInboxTests);
}

void _notificationActionTests() {
  late IngestHarness h;
  late String id;
  var built = 0;

  setUp(() async {
    built = 0;
    h = await openHarness();
    final (_, tx) = await h.ingest(kbApproval);
    id = tx!.id;
  });
  tearDown(() => h.close());

  Future<IngestDeps> deps() async {
    built++;
    return h.deps;
  }

  Future<TxStatus> status() async => (await h.deps.ledger.byId(id))!.status;

  test('include action includes the candidate', () async {
    await handleNotificationAction(
      _response(actionId: 'include', payload: id),
      deps,
    );

    expect(await status(), TxStatus.included);
    expect(h.notifier.cancelled, [id]);
  });

  test('exclude action excludes the candidate', () async {
    await handleNotificationAction(
      _response(actionId: 'exclude', payload: id),
      deps,
    );

    expect(await status(), TxStatus.excluded);
  });

  test('body tap and missing payload are ignored', () async {
    await handleNotificationAction(_response(payload: id), deps);
    await handleNotificationAction(_response(actionId: 'include'), deps);
    await handleNotificationAction(
      _response(actionId: 'other', payload: id),
      deps,
    );

    expect(built, 0);
    expect(await status(), TxStatus.pending);
  });

  test('exceptions are swallowed and logged', () async {
    final logs = <String>[];
    debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
    addTearDown(() => debugPrint = debugPrintThrottled);
    h.notifier.failing = true;

    await handleNotificationAction(
      _response(actionId: 'include', payload: id),
      deps,
    );
    await handleNotificationAction(
      _response(actionId: 'include', payload: id),
      () => Future<IngestDeps>.error(StateError('no db')),
    );

    expect(await status(), TxStatus.included);
    expect(logs, hasLength(2));
  });
}

void _ingestCallTests() {
  late IngestHarness h;

  setUp(() async => h = await openHarness());
  tearDown(() => h.close());

  MethodCall ingestCall(String text, {String? sender = 'KB'}) =>
      MethodCall('ingest', {'text': text, 'sender': sender});

  test('handleIngestCall stores and reports notified', () async {
    final r = await handleIngestCall(ingestCall(kbApproval), h.deps);

    expect(r['result'], 'stored');
    expect(r['notified'], isTrue);
    expect(r['dartMs'], isA<int>());
    final tx = await h.deps.ledger.byId(r['txId']! as String);
    expect(tx!.status, TxStatus.pending);
    expect(tx.sender, 'KB');
    expect(tx.receivedAt, harnessStart);
    expect(h.notifier.asked.map((t) => t.id), [tx.id]);
  });

  test('handleIngestCall reports filtered', () async {
    final r = await handleIngestCall(ingestCall(deposit, sender: null), h.deps);

    expect(r['result'], 'filtered');
    expect(r['notified'], isFalse);
    expect(r.containsKey('txId'), isFalse);
    expect(r['dartMs'], isA<int>());
  });

  test('stored without confirmation reports notified false', () async {
    final r = await handleIngestCall(ingestCall(noAmount), h.deps);

    expect(r['result'], 'stored');
    expect(r['notified'], isFalse);
    expect(h.notifier.asked, isEmpty);
  });

  test('notifier failure after storing still reports stored', () async {
    final logs = _captureLogs();
    h.notifier.failing = true;

    final r = await handleIngestCall(ingestCall(kbApproval), h.deps);

    expect(r['result'], 'stored');
    expect(r['notified'], isFalse);
    expect(r['notifyError'], 'StateError');
    expect(r['dartMs'], isA<int>());
    expect(await h.deps.ledger.byId(r['txId']! as String), isNotNull);
    expect(logs, hasLength(1));
  });

  test('failure before storing is reported as error type only', () async {
    final logs = _captureLogs();
    final ledger = FailingLedger(h.deps.ledger)..failWrites = true;

    final r = await handleIngestCall(
      ingestCall(kbApproval),
      _withLedger(h.deps, ledger),
    );

    expect(r['result'], 'error');
    expect(r['error'], 'StateError');
    expect(r.containsKey('txId'), isFalse);
    expect(r['dartMs'], isA<int>());
    expect(logs, hasLength(1));
  });

  test('missing text is reported as error', () async {
    _captureLogs();

    final r = await handleIngestCall(const MethodCall('ingest', {}), h.deps);

    expect(r['result'], 'error');
  });

  test('unknown method is not implemented', () {
    expect(
      () => handleIngestCall(const MethodCall('other'), h.deps),
      throwsA(isA<MissingPluginException>()),
    );
  });
}

void _drainInboxTests() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late IngestHarness h;
  late List<MethodCall> calls;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final receivedAt = DateTime(2026, 11, 27, 14, 5);

  Map<String, Object?> item(String id, String text, {String? sender}) => {
    'id': id,
    'text': text,
    'sender': sender,
    'receivedAtMs': receivedAt.millisecondsSinceEpoch,
  };

  void inbox(List<Map<String, Object?>> items) =>
      messenger.setMockMethodCallHandler(iosDiagnosticsChannel, (call) async {
        calls.add(call);
        return call.method == 'drainInbox' ? items : null;
      });

  setUp(() async {
    calls = [];
    h = await openHarness();
  });
  tearDown(() async {
    messenger.setMockMethodCallHandler(iosDiagnosticsChannel, null);
    await h.close();
  });

  test('keeps original time and sender and acks stored items', () async {
    inbox([
      item('a', kbApproval, sender: 'KB'),
      item('b', shinhanApproval),
      item('c', deposit),
    ]);

    await drainIosInbox(h.deps);

    expect(calls.map((c) => c.method), ['drainInbox', 'ackInbox']);
    expect(calls.last.arguments, {
      'ids': ['a', 'b', 'c'],
    });
    final pending = await h.deps.ledger.byStatus({TxStatus.pending});
    final kb = pending.singleWhere((t) => t.counterparty == '스타벅스');
    expect(kb.receivedAt, receivedAt);
    expect(kb.sender, 'KB');
    expect(pending.singleWhere((t) => t.counterparty == '김밥천국').sender, isNull);
  });

  test('late duplicate of a stored message is caught', () async {
    h.clock.value = receivedAt;
    await handleIngestCall(
      MethodCall('ingest', {'text': kbApproval, 'sender': 'KB'}),
      h.deps,
    );
    inbox([item('a', kbApproval, sender: 'KB')]);
    h.clock.value = receivedAt.add(const Duration(minutes: 2));

    await drainIosInbox(h.deps);

    final all = await h.deps.ledger.since(DateTime(2026));
    expect(all.where((t) => t.status != TxStatus.duplicate), hasLength(1));
  });

  test('failed items are not acked', () async {
    _captureLogs();
    inbox([item('a', kbApproval), item('b', shinhanApproval)]);
    final deps = _withLedger(
      h.deps,
      _RejectingLedger(h.deps.ledger, kbApproval),
    );

    await drainIosInbox(deps);

    expect(calls.last.method, 'ackInbox');
    expect(calls.last.arguments, {
      'ids': ['b'],
    });
  });

  test('nothing to ack when all fail', () async {
    _captureLogs();
    inbox([item('a', kbApproval)]);
    final deps = _withLedger(
      h.deps,
      _RejectingLedger(h.deps.ledger, kbApproval),
    );

    await drainIosInbox(deps);

    expect(calls.map((c) => c.method), ['drainInbox']);
  });

  test('missing channel is skipped', () async {
    await drainIosInbox(h.deps);

    expect(await h.deps.ledger.byStatus({TxStatus.pending}), isEmpty);
  });
}

List<String> _captureLogs() {
  final logs = <String>[];
  debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
  addTearDown(() => debugPrint = debugPrintThrottled);
  return logs;
}

IngestDeps _withLedger(IngestDeps d, LedgerRepository ledger) => IngestDeps(
  ledger: ledger,
  settings: d.settings,
  hints: d.hints,
  notifier: d.notifier,
  widgets: d.widgets,
  now: d.now,
  newId: d.newId,
);

/// [reject] 원문을 담은 거래 저장만 실패시킨다.
class _RejectingLedger extends FailingLedger {
  _RejectingLedger(super.inner, this.reject);

  final String reject;

  @override
  Future<Set<String>> saveIncoming(
    Transaction incoming,
    List<String> cancelIds, {
    required bool clearRawText,
  }) => incoming.rawText == reject
      ? Future.error(StateError('db failed'))
      : super.saveIncoming(incoming, cancelIds, clearRawText: clearRawText);
}
