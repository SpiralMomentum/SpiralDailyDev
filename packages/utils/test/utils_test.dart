import 'package:flutter_test/flutter_test.dart';
import 'package:utils/utils.dart';

class _FakeProvider extends TemplateMapProvider {
  _FakeProvider({
    required MapProviderType type,
    required this.name,
  }) : super(type: type, displayName: name);

  final String name;
  int initializeCount = 0;

  @override
  Future<void> initialize() async {
    initializeCount++;
  }

  @override
  String get integrationHint => 'Fake provider for testing';
}

void main() {
  test('registry initializes the default provider once', () async {
    final provider = _FakeProvider(
      type: MapProviderType.google,
      name: 'fake-google',
    );
    final registry = MapProviderRegistry(providers: [provider]);

    await registry.initializeActive();
    await registry.initializeActive();

    expect(provider.initializeCount, 1);
    expect(registry.activeProvider, provider);
  });

  test('switching provider triggers initialization and notifies listeners', () async {
    final google = _FakeProvider(type: MapProviderType.google, name: 'google');
    final naver = _FakeProvider(type: MapProviderType.naver, name: 'naver');
    final registry = MapProviderRegistry(providers: [google, naver]);
    await registry.initializeActive();

    var notified = false;
    registry.addListener(() => notified = true);

    await registry.switchTo(MapProviderType.naver);

    expect(notified, isTrue);
    expect(registry.activeProvider, naver);
    expect(google.initializeCount, 1);
    expect(naver.initializeCount, 1);
  });
}
