import 'package:flutter_test/flutter_test.dart';
import 'package:apps.news_reader/core/services/remote_config_service.dart';

void main() {
  group('MockRemoteConfigService', () {
    test('returns default values', () {
      final service = MockRemoteConfigService();
      expect(service.getString('min_version'), '1.0.0');
      expect(service.getString('latest_version'), '1.0.0');
      expect(service.getBool('force_update_enabled'), false);
    });

    test('returns overridden values', () {
      final service = MockRemoteConfigService(overrides: {
        'min_version': '2.0.0',
        'force_update_enabled': true,
      });
      expect(service.getString('min_version'), '2.0.0');
      expect(service.getBool('force_update_enabled'), true);
    });

    test('returns default for unknown keys', () {
      final service = MockRemoteConfigService();
      expect(service.getString('unknown', defaultValue: 'fallback'), 'fallback');
      expect(service.getInt('unknown', defaultValue: 42), 42);
      expect(service.getBool('unknown', defaultValue: true), true);
    });

    test('fetchAndActivate completes without error', () async {
      final service = MockRemoteConfigService();
      await expectLater(service.fetchAndActivate(), completes);
    });
  });
}
