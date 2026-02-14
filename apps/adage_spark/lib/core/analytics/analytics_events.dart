/// 앱 전체에서 사용하는 분석 이벤트 이름 상수.
///
/// 이벤트 이름을 한 곳에서 관리하여 오타와 불일치를 방지한다.
abstract final class AnalyticsEvents {
  /// 격언이 화면에 표시될 때
  static const String quoteViewed = 'quote_viewed';

  /// 다음 격언으로 셔플할 때
  static const String quoteShuffle = 'quote_shuffle';

  /// 새 격언이 추가될 때
  static const String quoteAdded = 'quote_added';
}
