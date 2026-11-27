import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/app/spend_ledger_app.dart';
import 'package:spend_ledger/features/ledger/domain/transaction.dart';

import '../../fixtures/messages.dart';
import '../../support/fakes.dart';

void main() {
  testWidgets('parse test page shows amount and category', (tester) async {
    late IngestHarness h;
    await tester.runAsync(() async => h = await openHarness());

    await tester.pumpWidget(SpendLedgerApp(deps: h.deps));
    await _settle(tester);
    await tester.tap(find.byTooltip('설정'));
    await _settle(tester);
    await tester.tap(find.text('파싱 테스트'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), kbApproval);
    await tester.tap(find.text('분석'));
    await _settle(tester);

    expect(find.text('6,500원'), findsOneWidget);
    expect(find.text('지출'), findsOneWidget);
    expect(find.text('통과'), findsOneWidget);
    expect(find.text('2026.11.27 14:03'), findsOneWidget);
    expect(find.text('보냄', skipOffstage: false), findsOneWidget);
    // 저장하지 않는다.
    await tester.runAsync(() async {
      expect(await h.deps.ledger.byStatus({TxStatus.pending}), isEmpty);
    });

    await tester.runAsync(h.close);
  });

  testWidgets('shortcut guide lists four steps', (tester) async {
    late IngestHarness h;
    await tester.runAsync(() async => h = await openHarness());
    await tester.pumpWidget(SpendLedgerApp(deps: h.deps));
    await _settle(tester);
    await tester.tap(find.byTooltip('설정'));
    await _settle(tester);
    await tester.tap(find.text('단축어 설정 안내'));
    await _settle(tester);
    expect(find.textContaining('4) 저장'), findsOneWidget);
    await tester.runAsync(h.close);
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
}
