import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/settings_data_source.dart';

class SharedPrefsSettingsDataSource implements SettingsDataSource {
  SharedPrefsSettingsDataSource({
    required SharedPreferences sharedPreferences,
  }) : _prefs = sharedPreferences;

  final SharedPreferences _prefs;

  static const _keyThemeMode = 'settings_theme_mode';
  static const _keyLocale = 'settings_locale';
  static const _keyPreferredCategories = 'settings_preferred_categories';
  static const _keyNotificationsEnabled = 'settings_notifications_enabled';
  static const _keyOnboardingCompleted = 'onboarding_completed';

  @override
  Future<Map<String, dynamic>> getSettings() async {
    return {
      'theme_mode': _prefs.getString(_keyThemeMode),
      'locale': _prefs.getString(_keyLocale),
      'preferred_categories': _prefs.getStringList(_keyPreferredCategories),
      'notifications_enabled': _prefs.getBool(_keyNotificationsEnabled),
    };
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> data) async {
    if (data['theme_mode'] != null) {
      await _prefs.setString(_keyThemeMode, data['theme_mode'] as String);
    }
    if (data['locale'] != null) {
      await _prefs.setString(_keyLocale, data['locale'] as String);
    }
    if (data['preferred_categories'] != null) {
      await _prefs.setStringList(
        _keyPreferredCategories,
        (data['preferred_categories'] as List).cast<String>(),
      );
    }
    if (data['notifications_enabled'] != null) {
      await _prefs.setBool(
        _keyNotificationsEnabled,
        data['notifications_enabled'] as bool,
      );
    }
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    return _prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_keyOnboardingCompleted, completed);
  }
}
