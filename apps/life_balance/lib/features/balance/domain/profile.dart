import 'package:equatable/equatable.dart';

import 'calendar_date.dart';

enum Sex { male, female }

class Profile extends Equatable {
  const Profile({
    required this.birthDate,
    required this.sex,
    required this.countryCode,
    this.manualLifespanYears,
  });

  final CalendarDate birthDate;
  final Sex sex;

  /// ISO alpha-2
  final String countryCode;
  final double? manualLifespanYears;

  Profile copyWith({
    CalendarDate? birthDate,
    Sex? sex,
    String? countryCode,
    double? manualLifespanYears,
    bool clearManualLifespan = false,
  }) =>
      Profile(
        birthDate: birthDate ?? this.birthDate,
        sex: sex ?? this.sex,
        countryCode: countryCode ?? this.countryCode,
        manualLifespanYears: clearManualLifespan
            ? null
            : (manualLifespanYears ?? this.manualLifespanYears),
      );

  @override
  List<Object?> get props =>
      [birthDate, sex, countryCode, manualLifespanYears];
}
