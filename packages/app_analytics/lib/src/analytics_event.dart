/// 분석 이벤트를 표현하는 불변 모델.
///
/// 이벤트 이름과 선택적 파라미터를 캡슐화한다.
class AnalyticsEvent {
  const AnalyticsEvent(this.name, [this.params]);

  /// 이벤트 이름 (예: 'memo_created').
  final String name;

  /// 이벤트에 첨부할 부가 데이터.
  final Map<String, Object>? params;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsEvent &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() =>
      'AnalyticsEvent($name${params != null ? ', $params' : ''})';
}
