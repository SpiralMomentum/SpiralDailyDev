import 'package:utils/result/result.dart';

import '../entities/user_preferences.dart';

abstract class SettingsRepository {
  Future<Result<UserPreferences>> getSettings();
  Future<Result<void>> updateSettings(UserPreferences preferences);
  Future<Result<bool>> isOnboardingCompleted();
  Future<Result<void>> setOnboardingCompleted(bool completed);
}
