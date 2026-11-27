import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/app/ingest_entry.dart';
import 'package:spend_ledger/features/ingest/data/ios_bridge.dart';
import 'package:spend_ledger/features/ingest/domain/ingest.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';

import '../fixtures/messages.dart';
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

  test('ingest failure is reported as error result', () async {
    final logs = <String>[];
    debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
    addTearDown(() => debugPrint = debugPrintThrottled);
    h.notifier.failing = true;

    final r = await handleIngestCall(ingestCall(kbApproval), h.deps);

    expect(r['result'], 'error');
    expect(r['error'], contains('notification failed'));
    expect(r['dartMs'], isA<int>());
    expect(logs, hasLength(1));
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
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() async => h = await openHarness());
  tearDown(() async {
    messenger.setMockMethodCallHandler(iosDiagnosticsChannel, null);
    await h.close();
  });

  test('ingests every drained message', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(iosDiagnosticsChannel, (call) async {
      calls.add(call.method);
      return [kbApproval, shinhanApproval];
    });

    await drainIosInbox(h.deps);

    expect(calls, ['drainInbox']);
    final pending = await h.deps.ledger.byStatus({TxStatus.pending});
    expect(
      pending.map((t) => t.counterparty),
      unorderedEquals(['스타벅스', '김밥천국']),
    );
  });

  test('missing channel is skipped', () async {
    await drainIosInbox(h.deps);

    expect(await h.deps.ledger.byStatus({TxStatus.pending}), isEmpty);
  });
}
