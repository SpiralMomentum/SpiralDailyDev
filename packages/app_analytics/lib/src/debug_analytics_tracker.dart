import 'package:app_logging/app_logging.dart';

import 'analytics_tracker.dart';

/// 디버그용 [AnalyticsTracker] 구현체.
///
/// [AppLogger]를 사용하여 이벤트를 콘솔에 출력한다.
/// 프로덕션 환경에서는 Firebase Analytics 등의 구현체로 교체한다.
class DebugAnalyticsTracker implements AnalyticsTracker {
  DebugAnalyticsTracker({AppLogger? logger})
      : _logger = logger ?? AppLogger(tag: 'Analytics');

  final AppLogger _logger;

  @override
  void trackEvent(String name, [Map<String, Object>? params]) {
    final paramInfo =
        params != null && params.isNotEmpty ? ', params: $params' : '';
    _logger.debug('[Event] $name$paramInfo');
  }

  @override
  void trackScreenView(String screenName) {
    _logger.debug('[ScreenView] $screenName');
  }

  @override
  void setUserProperty(String name, String value) {
    _logger.debug('[UserProperty] $name = $value');
  }
}
