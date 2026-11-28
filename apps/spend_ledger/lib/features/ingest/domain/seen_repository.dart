/// 같은 알림이 갱신되며 다시 올라오는 것을 한 번만 처리하기 위한 기록.
abstract interface class SeenRepository {
  /// 창 밖의 오래된 기록을 지우고, 같은 지문이 창 안에 없을 때만 기록하며 true.
  Future<bool> claim(String fingerprint, DateTime at, Duration window);

  /// 기록을 지운다. 처리에 실패한 알림이 다시 올라오면 다시 처리되게 한다.
  Future<void> release(String fingerprint);
}

/// 거르지 않는 기본 구현. iOS 경로가 쓴다.
class NoSeenFilter implements SeenRepository {
  const NoSeenFilter();

  @override
  Future<bool> claim(String fingerprint, DateTime at, Duration window) async =>
      true;

  @override
  Future<void> release(String fingerprint) async {}
}
