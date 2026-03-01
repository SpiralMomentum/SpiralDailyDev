import 'package:flutter_test/flutter_test.dart';

import 'package:apps.news_reader/core/feature_flags/feature_flag_service.dart';

void main() {
  group('LocalFeatureFlagService', () {
    test('isEnabled - 기본값에서 true/false 플래그를 올바르게 반환한다', () {
      final service = LocalFeatureFlagService();

      expect(service.isEnabled('show_search'), isTrue);
      expect(service.isEnabled('sdui_feed'), isFalse);
      expect(service.isEnabled('new_comment_ui'), isFalse);
    });

    test('isEnabled - 존재하지 않는 키는 false를 반환한다', () {
      final service = LocalFeatureFlagService();

      expect(service.isEnabled('nonexistent_flag'), isFalse);
    });

    test('getString - 문자열 값과 기본값을 올바르게 반환한다', () {
      final service = LocalFeatureFlagService();

      expect(service.getString('feed_layout_variant'), 'A');
      expect(
        service.getString('nonexistent_key', defaultValue: 'fallback'),
        'fallback',
      );
      // bool 타입 값에 대해 getString 호출 시 defaultValue 반환
      expect(
        service.getString('sdui_feed', defaultValue: 'default'),
        'default',
      );
    });

    test('getInt - 정수 값과 기본값을 올바르게 반환한다', () {
      final service = LocalFeatureFlagService();

      expect(service.getInt('max_comments_per_page'), 50);
      expect(service.getInt('nonexistent_key', defaultValue: 10), 10);
      // String 타입 값에 대해 getInt 호출 시 defaultValue 반환
      expect(
        service.getInt('feed_layout_variant', defaultValue: 99),
        99,
      );
    });

    test('custom defaults - 생성자에 전달한 맵이 기본값을 대체한다', () {
      final service = LocalFeatureFlagService(
        defaults: {
          'custom_flag': true,
          'custom_string': 'hello',
          'custom_int': 42,
        },
      );

      expect(service.isEnabled('custom_flag'), isTrue);
      expect(service.getString('custom_string'), 'hello');
      expect(service.getInt('custom_int'), 42);

      // 기본 플래그는 더 이상 존재하지 않는다
      expect(service.isEnabled('show_search'), isFalse);
      expect(service.getString('feed_layout_variant'), isEmpty);
    });
  });
}
