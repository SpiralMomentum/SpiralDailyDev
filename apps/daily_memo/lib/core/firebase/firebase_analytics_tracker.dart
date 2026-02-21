import 'package:app_analytics/app_analytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Firebase Analytics 기반 [AnalyticsTracker] 구현체.
class FirebaseAnalyticsTracker implements AnalyticsTracker {
  FirebaseAnalyticsTracker({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  void trackEvent(String name, [Map<String, Object>? params]) {
    _analytics.logEvent(
      name: name,
      parameters: params?.map(
        (key, value) => MapEntry(key, value),
      ),
    );
  }

  @override
  void trackScreenView(String screenName) {
    _analytics.logScreenView(screenName: screenName);
  }

  @override
  void setUserProperty(String name, String value) {
    _analytics.setUserProperty(name: name, value: value);
  }
}
