import 'package:app_logging/app_logging.dart';

import 'analytics_tracker.dart';

/// 디버그 환경에서 분석 이벤트를 [AppLogger]로 출력하는 구현체.
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
