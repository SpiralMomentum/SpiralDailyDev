import 'package:equatable/equatable.dart';

import '../../../balance/domain/balance.dart';
import '../../../balance/domain/calendar_date.dart';
import '../../../balance/domain/profile.dart';
import '../../../tone/domain/tone.dart';

enum OnboardingStep { birthDate, sex, country, lifespan, tone, done }

enum OnboardingError { futureBirthDate, invalidLifespan, saveFailed }

/// 수동 기대수명 허용 범위: 0 초과 150 이하.
const double maxManualLifespanYears = 150;

class OnboardingState extends Equatable {
  const OnboardingState({
    required this.step,
    required this.countryCode,
    this.birthDate,
    this.sex = Sex.male,
    this.manualLifespanYears,
    this.estimatedLifespanYears,
    this.tone = ToneId.stoic,
    this.firstBalance,
    this.saving = false,
    this.error,
  });

  final OnboardingStep step;
  final CalendarDate? birthDate;
  final Sex sex;
  final String countryCode;
  final double? manualLifespanYears;

  /// 생명표 추정 기대수명(세). lifespan 단계 진입 시 채워진다.
  final double? estimatedLifespanYears;
  final ToneId tone;

  /// complete() 성공 후 채워진다.
  final Balance? firstBalance;
  final bool saving;
  final OnboardingError? error;

  /// 모든 필드는 생략하면 유지, [error]는 생략하면 해제된다.
  OnboardingState copyWith({
    OnboardingStep? step,
    CalendarDate? birthDate,
    Sex? sex,
    String? countryCode,
    double? manualLifespanYears,
    bool clearManualLifespan = false,
    double? estimatedLifespanYears,
    ToneId? tone,
    Balance? firstBalance,
    bool? saving,
    OnboardingError? error,
  }) => OnboardingState(
    step: step ?? this.step,
    birthDate: birthDate ?? this.birthDate,
    sex: sex ?? this.sex,
    countryCode: countryCode ?? this.countryCode,
    manualLifespanYears: clearManualLifespan
        ? null
        : (manualLifespanYears ?? this.manualLifespanYears),
    estimatedLifespanYears:
        estimatedLifespanYears ?? this.estimatedLifespanYears,
    tone: tone ?? this.tone,
    firstBalance: firstBalance ?? this.firstBalance,
    saving: saving ?? this.saving,
    error: error,
  );

  @override
  List<Object?> get props => [
    step,
    birthDate,
    sex,
    countryCode,
    manualLifespanYears,
    estimatedLifespanYears,
    tone,
    firstBalance,
    saving,
    error,
  ];
}
