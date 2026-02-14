/// 분석 이벤트 트래킹 추상화 레이어.
///
/// Firebase Analytics 등 구체적인 구현체에 의존하지 않고
/// 이벤트 트래킹을 수행할 수 있도록 하는 인터페이스.
abstract class AnalyticsTracker {
  /// 이벤트를 기록한다.
  ///
  /// [name] 이벤트 이름 (예: 'world_map_viewed')
  /// [params] 이벤트에 부가할 파라미터 (선택)
  void trackEvent(String name, [Map<String, Object>? params]);

  /// 화면 조회를 기록한다.
  ///
  /// [screenName] 화면 이름 (예: 'WorldMapScreen')
  void trackScreenView(String screenName);
}
