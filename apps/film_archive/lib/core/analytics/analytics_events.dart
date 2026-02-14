/// 앱 전체에서 사용하는 분석 이벤트 이름 상수.
///
/// 이벤트 이름을 문자열 리터럴로 흩뿌리지 않고 한 곳에서 관리한다.
abstract final class AnalyticsEvents {
  /// 타임라인 화면이 조회됨
  static const String timelineViewed = 'timeline_viewed';

  /// 정렬 기준이 변경됨
  static const String sortOrderChanged = 'sort_order_changed';

  /// 영화 상세 화면이 조회됨
  static const String movieDetailViewed = 'movie_detail_viewed';
}
