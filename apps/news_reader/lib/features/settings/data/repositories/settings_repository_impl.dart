import 'package:flutter/material.dart';
import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';

import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl({
    required SettingsDataSource dataSource,
  }) : _dataSource = dataSource;

  final SettingsDataSource _dataSource;

  @override
  Future<Result<UserPreferences>> getSettings() async {
    try {
      final data = await _dataSource.getSettings();
      final preferences = _mapToPreferences(data);
      return Success(preferences);
    } catch (e, st) {
      return ErrorResult(
        LocalStorageFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateSettings(UserPreferences preferences) async {
    try {
      final data = _preferencesToMap(preferences);
      await _dataSource.saveSettings(data);
      return const Success(null);
    } catch (e, st) {
      return ErrorResult(
        LocalStorageFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<bool>> isOnboardingCompleted() async {
    try {
      final completed = await _dataSource.isOnboardingCompleted();
      return Success(completed);
    } catch (e, st) {
      return ErrorResult(
        LocalStorageFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> setOnboardingCompleted(bool completed) async {
    try {
      await _dataSource.setOnboardingCompleted(completed);
      return const Success(null);
    } catch (e, st) {
      return ErrorResult(
        LocalStorageFailure(
          message: e.toString(),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  UserPreferences _mapToPreferences(Map<String, dynamic> data) {
    return UserPreferences(
      themeMode: _parseThemeMode(data['theme_mode'] as String?),
      locale: _parseLocale(data['locale'] as String?),
      preferredCategories:
          (data['preferred_categories'] as List<dynamic>?)?.cast<String>() ??
              const [],
      notificationsEnabled: data['notifications_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _preferencesToMap(UserPreferences preferences) {
    return {
      'theme_mode': preferences.themeMode.name,
      'locale': preferences.locale.name,
      'preferred_categories': preferences.preferredCategories,
      'notifications_enabled': preferences.notificationsEnabled,
    };
  }

  ThemeMode _parseThemeMode(String? value) {
    if (value == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  AppLocale _parseLocale(String? value) {
    if (value == null) return AppLocale.ko;
    return AppLocale.values.firstWhere(
      (l) => l.name == value,
      orElse: () => AppLocale.ko,
    );
  }
}
