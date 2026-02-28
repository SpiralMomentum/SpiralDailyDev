abstract class AnalyticsService {
  void trackEvent(String name, [Map<String, Object>? params]);
  void trackScreenView(String screenName);
  void setUserProperty(String name, String value);
}

class MockAnalyticsService implements AnalyticsService {
  final List<String> trackedEvents = [];

  @override
  void trackEvent(String name, [Map<String, Object>? params]) {
    trackedEvents.add(name);
  }

  @override
  void trackScreenView(String screenName) {
    trackedEvents.add('screen:$screenName');
  }

  @override
  void setUserProperty(String name, String value) {}
}
