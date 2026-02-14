/// 앱 전역에서 사용하는 분석 이벤트 상수.
///
/// 이벤트 이름은 snake_case 규칙을 따른다.
abstract final class AnalyticsEvents {
  // -- 메모 CRUD --
  static const String memoCreated = 'memo_created';
  static const String memoUpdated = 'memo_updated';
  static const String memoDeleted = 'memo_deleted';

  // -- 탭 전환 --
  static const String calendarTabSelected = 'calendar_tab_selected';
  static const String memoListTabSelected = 'memo_list_tab_selected';
}
