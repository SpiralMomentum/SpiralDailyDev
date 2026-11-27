import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/ingest/data/ios_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(
    () => messenger.setMockMethodCallHandler(iosDiagnosticsChannel, null),
  );

  test('parseDiagnostics reads records newest first', () {
    final records = parseDiagnostics(
      '[{"at":1000,"path":"headless","engineMs":800,"dartMs":120,'
      '"totalMs":950,"result":"stored"},'
      '{"at":2000,"path":"fallback","engineMs":10000,"totalMs":10010,'
      '"result":"ready-timeout"}]',
    );

    expect(records.map((r) => r.at.millisecondsSinceEpoch), [2000, 1000]);
    expect(records.first.path, 'fallback');
    expect(records.first.dartMs, isNull);
    expect(records.last.dartMs, 120);
    expect(records.last.totalMs, 950);
    expect(records.last.result, 'stored');
  });

  test('loadDiagnostics returns empty without channel', () async {
    expect(await loadDiagnostics(), isEmpty);
  });

  test('loadDiagnostics parses channel list', () async {
    messenger.setMockMethodCallHandler(iosDiagnosticsChannel, (call) async {
      expect(call.method, 'list');
      return '[{"at":1,"path":"headless","engineMs":1,"dartMs":2,'
          '"totalMs":3,"result":"filtered"}]';
    });

    final records = await loadDiagnostics();

    expect(records.single.result, 'filtered');
  });
}
