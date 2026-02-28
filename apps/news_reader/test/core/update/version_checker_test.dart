import 'package:flutter_test/flutter_test.dart';
import 'package:apps.news_reader/core/services/remote_config_service.dart';
import 'package:apps.news_reader/core/update/version_checker.dart';

void main() {
  group('VersionChecker', () {
    test('returns none when current version equals min and latest', () {
      final config = MockRemoteConfigService(overrides: {
        'min_version': '1.0.0',
        'latest_version': '1.0.0',
      });
      final checker = VersionChecker(config);
      expect(checker.check(), UpdateRequirement.none);
    });

    test('returns forced when current version is below min_version', () {
      final config = MockRemoteConfigService(overrides: {
        'min_version': '2.0.0',
        'latest_version': '2.0.0',
      });
      final checker = VersionChecker(config);
      expect(checker.check(), UpdateRequirement.forced);
    });

    test('returns soft when current version is below latest but above min',
        () {
      final config = MockRemoteConfigService(overrides: {
        'min_version': '1.0.0',
        'latest_version': '1.1.0',
      });
      final checker = VersionChecker(config);
      expect(checker.check(), UpdateRequirement.soft);
    });

    test('returns none when current version is above latest', () {
      final config = MockRemoteConfigService(overrides: {
        'min_version': '0.9.0',
        'latest_version': '0.9.5',
      });
      final checker = VersionChecker(config);
      expect(checker.check(), UpdateRequirement.none);
    });

    test('handles patch version comparison', () {
      final config = MockRemoteConfigService(overrides: {
        'min_version': '1.0.1',
        'latest_version': '1.0.1',
      });
      final checker = VersionChecker(config);
      expect(checker.check(), UpdateRequirement.forced);
    });
  });
}
