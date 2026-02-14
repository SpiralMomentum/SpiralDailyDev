import 'package:app_logging/app_logging.dart';

import 'analytics_tracker.dart';

/// 디버그용 AnalyticsTracker 구현체.
///
/// AppLogger를 통해 이벤트를 콘솔에 출력한다.
/// 개발/테스트 환경에서 이벤트 발행 여부를 확인할 때 사용한다.
class DebugAnalyticsTracker implements AnalyticsTracker {
  DebugAnalyticsTracker({AppLogger? logger})
      : _logger = logger ?? AppLogger(tag: 'Analytics');

  final AppLogger _logger;

  @override
  void trackEvent(String name, [Map<String, Object>? params]) {
    final paramStr = params != null ? ', params: $params' : '';
    _logger.debug('[Event] $name$paramStr');
  }

  @override
  void trackScreenView(String screenName) {
    _logger.debug('[ScreenView] $screenName');
  }
}
