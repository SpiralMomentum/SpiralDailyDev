import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/app/ingest_entry.dart';
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
