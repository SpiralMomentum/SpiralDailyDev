import '../../balance/domain/profile.dart';

abstract interface class LifeTable {
  /// 100세 초과는 100세 값을 사용한다.
  double remainingYears({
    required String countryCode,
    required Sex sex,
    required int age,
  });

  List<String> get countryCodes;
}
