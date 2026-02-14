import 'package:app_logging/app_logging.dart';

import 'analytics_tracker.dart';

/// 디버그용 AnalyticsTracker 구현체.
///
/// AppLogger를 통해 이벤트와 화면 조회를 로그로 출력한다.
/// Firebase 등 실제 분석 서비스 연동 전까지 기본 구현으로 사용한다.
class DebugAnalyticsTracker implements AnalyticsTracker {
  DebugAnalyticsTracker({AppLogger? logger})
      : _logger = logger ?? AppLogger(tag: 'Analytics');

  final AppLogger _logger;

  @override
  void trackEvent(String name, [Map<String, Object>? params]) {
    if (params != null && params.isNotEmpty) {
      _logger.info('Event: $name | params: $params');
    } else {
      _logger.info('Event: $name');
    }
  }

  @override
  void trackScreenView(String screenName) {
    _logger.info('ScreenView: $screenName');
  }
}
