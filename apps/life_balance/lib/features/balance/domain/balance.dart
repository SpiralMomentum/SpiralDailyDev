import 'package:equatable/equatable.dart';

class Balance extends Equatable {
  const Balance({
    required this.remainingDays,
    required this.bonusDays,
    required this.totalDays,
  });

  /// 보너스면 0
  final int remainingDays;

  /// 보너스 아니면 0
  final int bonusDays;

  /// maturity - birth
  final int totalDays;

  bool get isBonus => bonusDays > 0 || remainingDays == 0;

  @override
  List<Object?> get props => [remainingDays, bonusDays, totalDays];
}
