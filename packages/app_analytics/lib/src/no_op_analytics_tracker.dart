import 'analytics_tracker.dart';

/// 아무 동작도 하지 않는 기본 구현.
///
/// Firebase 등 분석 서비스가 설정되지 않은 앱에서 사용한다.
class NoOpAnalyticsTracker implements AnalyticsTracker {
  const NoOpAnalyticsTracker();

  @override
  void trackEvent(String name, [Map<String, Object>? params]) {}

  @override
  void trackScreenView(String screenName) {}

  @override
  void setUserProperty(String name, String value) {}
}
