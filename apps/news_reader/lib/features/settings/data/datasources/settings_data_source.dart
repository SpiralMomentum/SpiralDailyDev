abstract class SettingsDataSource {
  Future<Map<String, dynamic>> getSettings();
  Future<void> saveSettings(Map<String, dynamic> data);
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted(bool completed);
}
