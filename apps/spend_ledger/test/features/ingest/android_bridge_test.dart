import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/ingest/data/android_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('spend_ledger/android');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  void mock(Future<Object?> Function(MethodCall) handler) {
    messenger.setMockMethodCallHandler(channel, (c) {
      calls.add(c);
      return handler(c);
    });
  }

  setUp(() => calls = []);
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('setAllowedPackages sends map', () async {
    mock((_) async => null);
    await const AndroidBridge().setAllowedPackages(['a', 'b']);
    expect(calls.single.method, 'setAllowedPackages');
    expect(calls.single.arguments, {
      'packages': ['a', 'b'],
    });
  });

  test('listenerEnabled returns native value', () async {
    mock((_) async => true);
    expect(await const AndroidBridge().listenerEnabled(), isTrue);
    expect(calls.single.method, 'listenerEnabled');
  });

  test('openListenerSettings calls method', () async {
    mock((_) async => null);
    await const AndroidBridge().openListenerSettings();
    expect(calls.single.method, 'openListenerSettings');
  });

  test('recentPackages parses list', () async {
    mock(
      (_) async => [
        {'package': 'p', 'label': 'L'},
      ],
    );
    expect(await const AndroidBridge().recentPackages(), const [
      RecentPackage(package: 'p', label: 'L'),
    ]);
    expect(calls.single.method, 'recentPackages');
  });

  test('missing plugin yields defaults', () async {
    const b = AndroidBridge();
    await b.setAllowedPackages(['a']);
    expect(await b.listenerEnabled(), isFalse);
    await b.openListenerSettings();
    expect(await b.recentPackages(), isEmpty);
  });
}
