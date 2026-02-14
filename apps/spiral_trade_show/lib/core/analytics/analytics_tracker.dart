/// 앱 전체에서 사용하는 분석 이벤트 추적 인터페이스.
///
/// 구현체를 교체하여 Firebase Analytics, 디버그 로거 등
/// 다양한 백엔드로 이벤트를 전송할 수 있다.
abstract class AnalyticsTracker {
  /// 커스텀 이벤트를 기록한다.
  ///
  /// [name] 이벤트 이름 (예: 'exhibition_list_viewed')
  /// [params] 이벤트에 첨부할 추가 파라미터 (선택)
  void trackEvent(String name, [Map<String, Object>? params]);

  /// 화면 조회 이벤트를 기록한다.
  ///
  /// [screenName] 화면 이름 (예: 'main_shelf_page')
  void trackScreenView(String screenName);
}
