/// InfoShelf 기능에서 사용하는 분석 이벤트 상수.
///
/// 이벤트 이름은 snake_case 규칙을 따르며,
/// Firebase Analytics 등 외부 서비스와의 호환성을 고려한다.
abstract final class AnalyticsEvents {
  /// 전시 목록 화면이 조회되었을 때 발행
  static const String exhibitionListViewed = 'exhibition_list_viewed';

  /// 전시 상세 화면이 조회되었을 때 발행
  static const String exhibitionDetailViewed = 'exhibition_detail_viewed';

  /// 탭 필터가 변경되었을 때 발행
  static const String tabFilterChanged = 'tab_filter_changed';
}
