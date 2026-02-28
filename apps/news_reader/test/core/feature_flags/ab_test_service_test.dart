import 'package:flutter_test/flutter_test.dart';

import 'package:apps.news_reader/core/feature_flags/ab_test_service.dart';
import 'package:apps.news_reader/core/feature_flags/feature_flag_service.dart';

void main() {
  group('AbTestService', () {
    test('getVariant - 설정된 변형 값을 반환한다', () {
      final flagService = LocalFeatureFlagService(
        defaults: {'feed_layout_variant': 'B'},
      );
      final abService = AbTestService(flagService);

      expect(abService.getVariant('feed_layout_variant'), 'B');
    });

    test('getVariant - 미설정 실험은 control을 반환한다', () {
      final flagService = LocalFeatureFlagService(defaults: {});
      final abService = AbTestService(flagService);

      expect(abService.getVariant('unknown_experiment'), 'control');
    });

    test('isExperimentActive - experiment_ 접두사 플래그를 확인한다', () {
      final flagService = LocalFeatureFlagService(
        defaults: {
          'experiment_feed_layout': true,
          'experiment_new_onboarding': false,
        },
      );
      final abService = AbTestService(flagService);

      expect(abService.isExperimentActive('feed_layout'), isTrue);
      expect(abService.isExperimentActive('new_onboarding'), isFalse);
      // 존재하지 않는 실험은 false
      expect(abService.isExperimentActive('nonexistent'), isFalse);
    });
  });
}
