/// 앱 전역에서 사용하는 분석 이벤트 상수.
///
/// 이벤트 이름은 snake_case 규칙을 따른다.
abstract final class AnalyticsEvents {
  // -- 세계 지도 --
  static const String worldMapViewed = 'world_map_viewed';

  // -- 국가 선택 --
  static const String countrySelected = 'country_selected';

  // -- 특산품 조회 --
  static const String specialtyViewed = 'specialty_viewed';
}
