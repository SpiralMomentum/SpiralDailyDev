/// 앱 내 분석 이벤트를 추적하기 위한 추상 인터페이스.
///
/// 구현체를 교체하여 Firebase Analytics, Amplitude 등
/// 다양한 백엔드로 이벤트를 전송할 수 있다.
abstract class AnalyticsTracker {
  /// 이름과 선택적 파라미터로 이벤트를 기록한다.
  void trackEvent(String name, [Map<String, Object>? params]);

  /// 화면 조회 이벤트를 기록한다.
  void trackScreenView(String screenName);
}
