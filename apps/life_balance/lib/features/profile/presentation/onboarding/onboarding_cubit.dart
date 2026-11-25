import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../balance/domain/balance_calculator.dart';
import '../../../balance/domain/calendar_date.dart';
import '../../../balance/domain/profile.dart';
import '../../../life_table/domain/life_table.dart';
import '../../../ongoing_notification/data/ongoing_notifier.dart';
import '../../../tone/domain/tone.dart';
import '../../domain/lifespan_validation.dart';
import '../../domain/profile_repository.dart';
import '../../domain/settings.dart';
import 'onboarding_state.dart';

const _fallbackCountry = 'KR';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required ProfileRepository repo,
    required OngoingNotifier notifier,
    required LifeTable table,
    required CalendarDate Function() today,
    required String? deviceCountry,
    required Future<void> Function(Profile, AppSettings) onComplete,
  }) : _repo = repo,
       _notifier = notifier,
       _table = table,
       _today = today,
       _onComplete = onComplete,
       super(
         OnboardingState(
           step: OnboardingStep.birthDate,
           countryCode: table.countryCodes.contains(deviceCountry)
               ? deviceCountry!
               : _fallbackCountry,
         ),
       );

  final ProfileRepository _repo;
  final OngoingNotifier _notifier;
  final LifeTable _table;
  final CalendarDate Function() _today;
  final Future<void> Function(Profile, AppSettings) _onComplete;

  void setBirthDate(CalendarDate date) {
    if (_today().isBefore(date)) {
      emit(state.copyWith(error: OnboardingError.futureBirthDate));
      return;
    }
    emit(state.copyWith(birthDate: date));
  }

  void setSex(Sex sex) => emit(state.copyWith(sex: sex));

  void setCountry(String code) {
    if (!_table.countryCodes.contains(code)) return;
    emit(state.copyWith(countryCode: code));
  }

  /// null이면 수동값 해제. 0 이하, 150 초과, NaN은 오류 상태이며 저장값이 비워진다.
  /// 현재 나이보다 작은 값은 허용한다(보너스 잔고).
  void setManualLifespan(double? years) {
    if (years == null) {
      emit(state.copyWith(clearManualLifespan: true));
      return;
    }
    if (!isValidManualLifespan(years)) {
      // 잘못된 입력은 저장값을 비우고 유효한 입력이 들어올 때까지 오류를 유지한다.
      emit(
        state.copyWith(
          clearManualLifespan: true,
          error: OnboardingError.invalidLifespan,
        ),
      );
      return;
    }
    emit(state.copyWith(manualLifespanYears: years));
  }

  void setTone(ToneId tone) => emit(state.copyWith(tone: tone));

  void next() {
    final step = state.step;
    if (state.error == OnboardingError.invalidLifespan) return;
    if (step == OnboardingStep.birthDate && state.birthDate == null) return;
    if (step == OnboardingStep.tone || step == OnboardingStep.done) return;
    _goTo(OnboardingStep.values[step.index + 1]);
  }

  void back() {
    final step = state.step;
    if (step == OnboardingStep.birthDate || step == OnboardingStep.done) {
      return;
    }
    _goTo(OnboardingStep.values[step.index - 1]);
  }

  void _goTo(OnboardingStep step) {
    final birth = state.birthDate;
    if (step == OnboardingStep.lifespan && birth != null) {
      final estimate = estimatedLifespanYears(
        profile: Profile(
          birthDate: birth,
          sex: state.sex,
          countryCode: state.countryCode,
        ),
        today: _today(),
        table: _table,
      );
      emit(state.copyWith(step: step, estimatedLifespanYears: estimate));
      return;
    }
    emit(state.copyWith(step: step));
  }

  Future<void> complete() async {
    final birth = state.birthDate;
    if (birth == null ||
        state.saving ||
        state.error == OnboardingError.invalidLifespan) {
      return;
    }
    final profile = Profile(
      birthDate: birth,
      sex: state.sex,
      countryCode: state.countryCode,
      manualLifespanYears: state.manualLifespanYears,
    );
    var settings = AppSettings.defaults.copyWith(tone: state.tone);
    emit(state.copyWith(saving: true));
    bool? granted;
    try {
      // 첫 알림이 뜨기 전에 권한을 확정하고, 거부되면 설정을 끈 채로 저장한다.
      if (settings.ongoingNotification) {
        granted = await _notifier.requestPermission();
        if (!granted) settings = settings.copyWith(ongoingNotification: false);
      }
      await _repo.saveProfile(profile);
      await _repo.saveSettings(settings);
      await _onComplete(profile, settings);
    } catch (_) {
      emit(state.copyWith(saving: false, error: OnboardingError.saveFailed));
      return;
    }
    final today = _today();
    final maturity = maturityDate(
      profile: profile,
      today: today,
      table: _table,
    );
    emit(
      state.copyWith(
        step: OnboardingStep.done,
        saving: false,
        notificationGranted: granted,
        firstBalance: computeBalance(
          birth: birth,
          maturity: maturity,
          today: today,
        ),
      ),
    );
  }
}
