import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../balance/domain/balance_format.dart';
import '../../balance/domain/calendar_date.dart';
import '../../balance/domain/profile.dart';
import '../../ongoing_notification/data/ongoing_notifier.dart';
import '../../profile/domain/lifespan_validation.dart';
import '../../profile/domain/profile_repository.dart';
import '../../profile/domain/settings.dart';
import '../../tone/domain/tone.dart';

enum SettingsError { futureBirthDate, invalidLifespan, saveFailed }

class SettingsState extends Equatable {
  const SettingsState({
    required this.profile,
    required this.settings,
    this.permissionDenied = false,
    this.error,
  });

  final Profile profile;
  final AppSettings settings;
  final bool permissionDenied;
  final SettingsError? error;

  @override
  List<Object?> get props => [profile, settings, permissionDenied, error];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required ProfileRepository repo,
    required OngoingNotifier notifier,
    required CalendarDate Function() today,
    required Profile initialProfile,
    required AppSettings initialSettings,
    required Future<void> Function(Profile, AppSettings) onChanged,
  }) : _repo = repo,
       _notifier = notifier,
       _today = today,
       _onChanged = onChanged,
       super(SettingsState(profile: initialProfile, settings: initialSettings));

  final ProfileRepository _repo;
  final OngoingNotifier _notifier;
  final CalendarDate Function() _today;
  final Future<void> Function(Profile, AppSettings) _onChanged;

  Future<void> updateProfile(Profile profile) async {
    if (_today().isBefore(profile.birthDate)) {
      emit(_with(error: SettingsError.futureBirthDate));
      return;
    }
    await _persist(profile, state.settings);
  }

  /// null이면 자동(생명표). 잘못된 값은 저장하지 않고 오류 상태로 알린다.
  Future<void> setManualLifespan(double? years) {
    if (years == null) {
      return updateProfile(state.profile.copyWith(clearManualLifespan: true));
    }
    if (!isValidManualLifespan(years)) {
      emit(_with(error: SettingsError.invalidLifespan));
      return Future.value();
    }
    return updateProfile(state.profile.copyWith(manualLifespanYears: years));
  }

  Future<void> setUnit(BalanceUnit unit) =>
      _persist(state.profile, state.settings.copyWith(unit: unit));

  Future<void> setTone(ToneId tone) =>
      _persist(state.profile, state.settings.copyWith(tone: tone));

  Future<void> setThemePref(ThemePref pref) =>
      _persist(state.profile, state.settings.copyWith(themePref: pref));

  Future<void> setOngoing(bool on) async {
    if (on) {
      final granted = await _notifier.requestPermission();
      if (!granted) {
        emit(
          SettingsState(
            profile: state.profile,
            settings: state.settings.copyWith(ongoingNotification: false),
            permissionDenied: true,
          ),
        );
        return;
      }
    }
    await _persist(
      state.profile,
      state.settings.copyWith(ongoingNotification: on),
    );
  }

  SettingsState _with({SettingsError? error}) => SettingsState(
    profile: state.profile,
    settings: state.settings,
    error: error,
  );

  Future<void> _persist(Profile profile, AppSettings settings) async {
    try {
      if (profile != state.profile) await _repo.saveProfile(profile);
      if (settings != state.settings) await _repo.saveSettings(settings);
      emit(SettingsState(profile: profile, settings: settings));
      await _onChanged(profile, settings);
    } catch (_) {
      emit(_with(error: SettingsError.saveFailed));
    }
  }
}
