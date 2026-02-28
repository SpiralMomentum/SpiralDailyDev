import 'package:flutter/material.dart';

enum AppLocale { ko, en }

class UserPreferences {
  const UserPreferences({
    this.themeMode = ThemeMode.system,
    this.locale = AppLocale.ko,
    this.preferredCategories = const [],
    this.notificationsEnabled = true,
  });

  final ThemeMode themeMode;
  final AppLocale locale;
  final List<String> preferredCategories;
  final bool notificationsEnabled;

  UserPreferences copyWith({
    ThemeMode? themeMode,
    AppLocale? locale,
    List<String>? preferredCategories,
    bool? notificationsEnabled,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserPreferences) return false;
    return themeMode == other.themeMode &&
        locale == other.locale &&
        _listEquals(preferredCategories, other.preferredCategories) &&
        notificationsEnabled == other.notificationsEnabled;
  }

  @override
  int get hashCode => Object.hash(
        themeMode,
        locale,
        Object.hashAll(preferredCategories),
        notificationsEnabled,
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
