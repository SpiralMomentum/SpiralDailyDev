import 'dart:math';

/// 발현 확률 규칙 (명세 1절 "발현 조건").
/// - 시작 0%, 시행마다 상승, 발현 시 초기화.
/// - 시행당 증가폭은 10%p 이하 랜덤: 0.1%p ~ 10%p 를 0.1%p 단위 균등 추첨.
/// - 천장: 확률이 100% 에 닿으면 다음 시행은 반드시 발현.
/// 확률은 천분율 정수(0~1000)로 다뤄 부동소수 오차를 피한다.
abstract final class ManifestationGauge {
  static const int ceilingPermille = 1000;
  static const int maxIncrementPermille = 100;

  /// 현재 확률로 이번 시행의 발현 여부를 추첨한다.
  static bool roll(int gaugePermille, Random random) {
    if (gaugePermille <= 0) return false;
    if (gaugePermille >= ceilingPermille) return true;
    return random.nextInt(ceilingPermille) < gaugePermille;
  }

  /// 이번 시행 뒤의 확률.
  static int next(int gaugePermille, {required bool manifested, required Random random}) {
    if (manifested) return 0;
    final increment = random.nextInt(maxIncrementPermille) + 1;
    return min(ceilingPermille, gaugePermille + increment);
  }
}
