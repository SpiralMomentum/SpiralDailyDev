import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/app/routes.dart';
import 'package:spend_ledger/app/spend_ledger_app.dart';
import 'package:spend_ledger/features/ingest/domain/ingest.dart';

import '../fixtures/messages.dart';
import '../support/failing_ledger.dart';
import '../support/fakes.dart';

void main() {
  test('routeForWidgetUri maps candidates only', () {
    expect(
      routeForWidgetUri(Uri.parse('spendledger://candidates')),
      AppRoutes.candidates,
    );
    expect(routeForWidgetUri(Uri.parse('spendledger://home')), isNull);
    expect(routeForWidgetUri(null), isNull);
  });

  testWidgets('app shows home total', (tester) async {
    late IngestHarness h;
    await tester.runAsync(() async {
      h = await openHarness();
      final (_, a) = await h.ingest(kbApproval);
      await resolveCandidate(a!.id, true, h.deps);
      await h.ingest(shinhanApproval);
    });

    await tester.pumpWidget(SpendLedgerApp(deps: h.deps));
    await _settle(tester);

    expect(find.text('6,500원'), findsWidgets);
    expect(find.text('확인 대기 1건'), findsOneWidget);

    await tester.tap(find.text('확인 대기 1건'));
    await _settle(tester);

    expect(find.text('김밥천국'), findsOneWidget);

    await tester.runAsync(h.close);
  });

  testWidgets('cold start from widget candidates tap opens candidates', (
    tester,
  ) async {
    late IngestHarness h;
    await tester.runAsync(() async {
      h = await openHarness();
      await h.ingest(kbApproval);
    });

    await tester.pumpWidget(
      SpendLedgerApp(
        deps: h.deps,
        initialWidgetUri: () async => Uri.parse('spendledger://candidates'),
      ),
    );
    await _settle(tester);

    expect(find.text('스타벅스'), findsWidgets);
    expect(appNavigatorKey.currentState!.canPop(), isTrue);

    await tester.runAsync(h.close);
  });

  testWidgets('initial edit id opens edit page over home', (tester) async {
    late IngestHarness h;
    late String id;
    await tester.runAsync(() async {
      h = await openHarness();
      final (_, a) = await h.ingest(kbApproval);
      id = a!.id;
    });

    await tester.pumpWidget(SpendLedgerApp(deps: h.deps, initialEditId: id));
    await _settle(tester);

    expect(find.text('거래 수정'), findsOneWidget);
    expect(find.widgetWithText(TextField, '스타벅스'), findsOneWidget);
    expect(appNavigatorKey.currentState!.canPop(), isTrue);

    await tester.runAsync(h.close);
  });

  testWidgets('failed edit save shows error and stays', (tester) async {
    late IngestHarness h;
    late String id;
    await tester.runAsync(() async {
      h = await openHarness();
      final (_, a) = await h.ingest(kbApproval);
      id = a!.id;
    });
    final ledger = FailingLedger(h.deps.ledger)..failWrites = true;

    await tester.pumpWidget(
      SpendLedgerApp(deps: withLedger(h.deps, ledger), initialEditId: id),
    );
    await _settle(tester);
    await tester.scrollUntilVisible(
      find.text('저장'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('저장'));
    await _settle(tester);

    expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('거래 수정'), findsOneWidget);

    await tester.runAsync(h.close);
  });
}

/// 실제 DB 호출(ffi)이 끝나도록 실시간으로 기다리며 프레임을 진행한다.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
}
