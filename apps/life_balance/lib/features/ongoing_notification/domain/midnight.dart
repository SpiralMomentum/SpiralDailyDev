/// [now] 이후 처음 오는 로컬 자정 + 1분까지 남은 시간.
///
/// 정각 자정이면 다음 날 자정을 기준으로 한다. `DateTime` 로컬 생성자가
/// 날짜 넘김과 일광절약 전환을 정규화한다.
Duration delayUntilNextRefresh(DateTime now) {
  final next = DateTime(now.year, now.month, now.day + 1, 0, 1);
  return next.difference(now);
}
