import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';

import 'package:apps.news_reader/features/settings/domain/entities/user_preferences.dart';
import 'package:apps.news_reader/features/settings/domain/repositories/settings_repository.dart';
import 'package:apps.news_reader/features/settings/domain/usecases/get_settings.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late GetSettings usecase;
  late MockSettingsRepository repository;

  setUp(() {
    repository = MockSettingsRepository();
    usecase = GetSettings(repository);
  });

  const tPreferences = UserPreferences(
    themeMode: ThemeMode.dark,
    locale: AppLocale.en,
    preferredCategories: ['technology', 'science'],
    notificationsEnabled: false,
  );

  group('GetSettings', () {
    test('returns UserPreferences on success', () async {
      when(() => repository.getSettings())
          .thenAnswer((_) async => const Success(tPreferences));

      final result = await usecase();

      expect(result, isA<Success<UserPreferences>>());
      final success = result as Success<UserPreferences>;
      expect(success.data.themeMode, ThemeMode.dark);
      expect(success.data.locale, AppLocale.en);
      expect(success.data.preferredCategories, ['technology', 'science']);
      expect(success.data.notificationsEnabled, false);
      verify(() => repository.getSettings()).called(1);
    });

    test('returns ErrorResult on failure', () async {
      when(() => repository.getSettings()).thenAnswer(
        (_) async =>
            ErrorResult(const LocalStorageFailure(message: 'Storage error')),
      );

      final result = await usecase();

      expect(result, isA<ErrorResult<UserPreferences>>());
      final error = result as ErrorResult<UserPreferences>;
      expect(error.failure.message, 'Storage error');
    });
  });
}
