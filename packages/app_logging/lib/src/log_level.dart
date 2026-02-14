/// 로그 심각도 레벨.
///
/// 필터링 정책: 출력 레벨 이상의 로그만 기록된다.
/// 예) output level = warning → warning, error만 출력.
enum LogLevel implements Comparable<LogLevel> {
  debug(0),
  info(1),
  warning(2),
  error(3);

  const LogLevel(this.priority);

  final int priority;

  @override
  int compareTo(LogLevel other) => priority - other.priority;

  bool operator >=(LogLevel other) => priority >= other.priority;
}
