import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/ingest/data/ios_bridge.dart';
import 'package:spend_ledger/features/ingest/presentation/diagnostics_page.dart';

Future<void> _show(WidgetTester tester, List<IngestDiagnostic> records) async {
  await tester.pumpWidget(
    MaterialApp(home: DiagnosticsPage(load: () async => records)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows empty state', (tester) async {
    await _show(tester, const []);

    expect(find.text('기록이 없어요'), findsOneWidget);
  });

  testWidgets('shows each record with timings', (tester) async {
    await _show(tester, [
      IngestDiagnostic(
        at: DateTime(2026, 11, 27, 20, 1, 2),
        path: 'headless',
        engineMs: 800,
        dartMs: 120,
        totalMs: 950,
        result: 'stored',
      ),
      IngestDiagnostic(
        at: DateTime(2026, 11, 27, 19),
        path: 'fallback',
        engineMs: 10000,
        dartMs: null,
        totalMs: 10010,
        result: 'ready-timeout',
      ),
    ]);

    expect(find.text('11/27 20:01:02 · 경로 headless · stored'), findsOneWidget);
    expect(
      find.text('engineMs 800 · dartMs 120 · totalMs 950'),
      findsOneWidget,
    );
    expect(
      find.text('11/27 19:00:00 · 경로 fallback · ready-timeout'),
      findsOneWidget,
    );
    expect(
      find.text('engineMs 10000 · dartMs - · totalMs 10010'),
      findsOneWidget,
    );
  });
}
