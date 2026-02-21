/// 앱 내 사용자 행동을 추적하기 위한 추상 인터페이스.
///
/// 구현체를 교체하여 Firebase Analytics, Amplitude 등으로 전환할 수 있다.
abstract class AnalyticsTracker {
  /// 이벤트를 추적한다.
  ///
  /// [name]은 이벤트 이름, [params]는 부가 파라미터이다.
  void trackEvent(String name, [Map<String, Object>? params]);

  /// 화면 조회를 추적한다.
  void trackScreenView(String screenName);

  /// 사용자 속성을 설정한다.
  void setUserProperty(String name, String value);
}
