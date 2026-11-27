import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/life_table/domain/life_table.dart';

class FakeLifeTable implements LifeTable {
  FakeLifeTable(this.values);
  final Map<int, double> values;

  @override
  double remainingYears({
    required String countryCode,
    required Sex sex,
    required int age,
  }) =>
      values[age]!;

  @override
  List<String> get countryCodes => const ['KR'];
}
