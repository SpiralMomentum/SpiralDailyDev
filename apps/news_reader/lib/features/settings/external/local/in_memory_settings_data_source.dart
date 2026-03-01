import '../../data/datasources/settings_data_source.dart';

/// In-memory implementation for testing.
class InMemorySettingsDataSource implements SettingsDataSource {
  Map<String, dynamic> _settings = {};
  bool _onboardingCompleted = false;

  @override
  Future<Map<String, dynamic>> getSettings() async {
    return Map<String, dynamic>.from(_settings);
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> data) async {
    _settings = Map<String, dynamic>.from(data);
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    return _onboardingCompleted;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    _onboardingCompleted = completed;
  }
}
