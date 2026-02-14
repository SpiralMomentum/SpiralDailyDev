/// 앱 전체에서 사용하는 분석 이벤트 이름 상수.
abstract final class AnalyticsEvents {
  /// 몬스터 상세 조회 시
  static const String monsterViewed = 'monster_viewed';

  /// 리스트/맵 뷰 모드 전환 시
  static const String viewModeToggled = 'view_mode_toggled';

  /// 즐겨찾기 토글 시
  static const String favoriteToggled = 'favorite_toggled';

  /// 지도에서 국가 선택 시
  static const String countrySelected = 'country_selected';
}
