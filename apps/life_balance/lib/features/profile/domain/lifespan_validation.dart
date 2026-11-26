/// 수동 기대수명 허용 범위: 0 초과 150 이하.
const double maxManualLifespanYears = 150;

/// NaN/무한대, 0 이하, 150 초과는 거부한다. 현재 나이보다 작은 값은 허용한다(보너스 잔고).
bool isValidManualLifespan(double years) =>
    years > 0 && years <= maxManualLifespanYears;
