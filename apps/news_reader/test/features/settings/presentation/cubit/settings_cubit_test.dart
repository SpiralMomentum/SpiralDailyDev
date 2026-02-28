import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';

import 'package:apps.news_reader/features/settings/domain/entities/user_preferences.dart';
import 'package:apps.news_reader/features/settings/domain/usecases/get_settings.dart';
import 'package:apps.news_reader/features/settings/domain/usecases/update_settings.dart';
import 'package:apps.news_reader/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:apps.news_reader/features/settings/presentation/cubit/settings_state.dart';

class MockGetSettings extends Mock implements GetSettings {}

class MockUpdateSettings extends Mock implements UpdateSettings {}

void main() {
  late MockGetSettings getSettings;
  late MockUpdateSettings updateSettings;

  const tPreferences = UserPreferences(
    themeMode: ThemeMode.dark,
    locale: AppLocale.en,
    preferredCategories: ['technology'],
    notificationsEnabled: true,
  );

  setUp(() {
    getSettings = MockGetSettings();
    updateSettings = MockUpdateSettings();
  });

  setUpAll(() {
    registerFallbackValue(const UserPreferences());
  });

  SettingsCubit buildCubit() => SettingsCubit(
        getSettings: getSettings,
        updateSettings: updateSettings,
      );

  group('SettingsCubit', () {
    blocTest<SettingsCubit, SettingsState>(
      'emits [loading, loaded] on successful loadSettings',
      build: () {
        when(() => getSettings())
            .thenAnswer((_) async => const Success(tPreferences));
        return buildCubit();
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        const SettingsState(status: SettingsStatus.loading),
        const SettingsState(
          status: SettingsStatus.loaded,
          preferences: tPreferences,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits [loading, error] on failed loadSettings',
      build: () {
        when(() => getSettings()).thenAnswer(
          (_) async =>
              ErrorResult(const LocalStorageFailure(message: 'DB error')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        const SettingsState(status: SettingsStatus.loading),
        const SettingsState(
          status: SettingsStatus.error,
          errorMessage: 'DB error',
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits loaded with updated theme on changeTheme',
      build: () {
        when(() => updateSettings(any()))
            .thenAnswer((_) async => const Success(null));
        return buildCubit();
      },
      seed: () => const SettingsState(
        status: SettingsStatus.loaded,
        preferences: UserPreferences(),
      ),
      act: (cubit) => cubit.changeTheme(ThemeMode.dark),
      expect: () => [
        const SettingsState(
          status: SettingsStatus.loaded,
          preferences: UserPreferences(themeMode: ThemeMode.dark),
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits loaded with updated locale on changeLocale',
      build: () {
        when(() => updateSettings(any()))
            .thenAnswer((_) async => const Success(null));
        return buildCubit();
      },
      seed: () => const SettingsState(
        status: SettingsStatus.loaded,
        preferences: UserPreferences(),
      ),
      act: (cubit) => cubit.changeLocale(AppLocale.en),
      expect: () => [
        const SettingsState(
          status: SettingsStatus.loaded,
          preferences: UserPreferences(locale: AppLocale.en),
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits loaded with toggled notifications on toggleNotifications',
      build: () {
        when(() => updateSettings(any()))
            .thenAnswer((_) async => const Success(null));
        return buildCubit();
      },
      seed: () => const SettingsState(
        status: SettingsStatus.loaded,
        preferences: UserPreferences(notificationsEnabled: true),
      ),
      act: (cubit) => cubit.toggleNotifications(false),
      expect: () => [
        const SettingsState(
          status: SettingsStatus.loaded,
          preferences: UserPreferences(notificationsEnabled: false),
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'emits error when updateSettings fails on changeTheme',
      build: () {
        when(() => updateSettings(any())).thenAnswer(
          (_) async =>
              ErrorResult(const LocalStorageFailure(message: 'Save failed')),
        );
        return buildCubit();
      },
      seed: () => const SettingsState(
        status: SettingsStatus.loaded,
        preferences: UserPreferences(),
      ),
      act: (cubit) => cubit.changeTheme(ThemeMode.dark),
      expect: () => [
        const SettingsState(
          status: SettingsStatus.error,
          errorMessage: 'Save failed',
        ),
      ],
    );
  });
}
