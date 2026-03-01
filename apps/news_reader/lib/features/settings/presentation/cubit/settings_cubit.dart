import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utils/result/result.dart';

import '../../domain/entities/user_preferences.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/update_settings.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required GetSettings getSettings,
    required UpdateSettings updateSettings,
  })  : _getSettings = getSettings,
        _updateSettings = updateSettings,
        super(const SettingsState());

  final GetSettings _getSettings;
  final UpdateSettings _updateSettings;

  Future<void> loadSettings() async {
    emit(state.copyWith(status: SettingsStatus.loading));

    final result = await _getSettings();
    switch (result) {
      case Success(data: final prefs):
        emit(state.copyWith(
          status: SettingsStatus.loaded,
          preferences: prefs,
          errorMessage: () => null,
        ));
      case ErrorResult(failure: final failure):
        emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: () => failure.message,
        ));
    }
  }

  Future<void> changeTheme(ThemeMode themeMode) async {
    final updated = state.preferences.copyWith(themeMode: themeMode);
    await _saveAndEmit(updated);
  }

  Future<void> changeLocale(AppLocale locale) async {
    final updated = state.preferences.copyWith(locale: locale);
    await _saveAndEmit(updated);
  }

  Future<void> toggleNotifications(bool enabled) async {
    final updated = state.preferences.copyWith(notificationsEnabled: enabled);
    await _saveAndEmit(updated);
  }

  Future<void> updateCategories(List<String> categories) async {
    final updated = state.preferences.copyWith(preferredCategories: categories);
    await _saveAndEmit(updated);
  }

  Future<void> _saveAndEmit(UserPreferences updated) async {
    final result = await _updateSettings(updated);
    switch (result) {
      case Success():
        emit(state.copyWith(
          status: SettingsStatus.loaded,
          preferences: updated,
          errorMessage: () => null,
        ));
      case ErrorResult(failure: final failure):
        emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: () => failure.message,
        ));
    }
  }
}
