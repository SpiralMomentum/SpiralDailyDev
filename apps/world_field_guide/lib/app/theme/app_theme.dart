import 'package:flutter/material.dart';

enum AppThemeVariant { light, dark, accent }

abstract class AppTheme {
  static const Color primaryBlue = Color(0xFF1390F1);
  static const Color deepNavy = Color(0xFF0B3F6A);
  static const Color paleSky = Color(0xFFF1F7FF);
  static const Color mapCanvas = Color(0xFFE3F1FF);
  static const Color textSecondary = Color(0xFF5C708D);

  static const Color midnight = Color(0xFF050E18);
  static const Color midnightSurface = Color(0xFF0F1E31);

  static const Color accentPrimary = Color(0xFFFF6F3C);
  static const Color accentSecondary = Color(0xFF5C2CF2);
  static const Color accentBackground = Color(0xFFFFF3EB);

  static ThemeData resolve(AppThemeVariant variant) {
    switch (variant) {
      case AppThemeVariant.dark:
        return dark;
      case AppThemeVariant.accent:
        return accent;
      case AppThemeVariant.light:
      default:
        return light;
    }
  }

  static ThemeMode modeFor(AppThemeVariant variant) {
    return variant == AppThemeVariant.dark ? ThemeMode.dark : ThemeMode.light;
  }

  static ThemeData get light {
    final base = ThemeData.from(colorScheme: _lightScheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: paleSky,
      textTheme: base.textTheme.apply(
        bodyColor: deepNavy,
        displayColor: deepNavy,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: deepNavy,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.from(colorScheme: _darkScheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: midnight,
      appBarTheme: const AppBarTheme(
        backgroundColor: midnightSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.white,
        foregroundColor: midnight,
      ),
      cardColor: midnightSurface,
    );
  }

  static ThemeData get accent {
    final base = ThemeData.from(
      colorScheme: _accentScheme,
      useMaterial3: true,
    );
    return base.copyWith(
      scaffoldBackgroundColor: accentBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: accentSecondary,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentSecondary,
        foregroundColor: Colors.white,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: accentSecondary,
        displayColor: accentSecondary,
      ),
    );
  }

  static const ColorScheme _lightScheme = ColorScheme.light(
    primary: primaryBlue,
    onPrimary: Colors.white,
    secondary: deepNavy,
    onSecondary: Colors.white,
    error: Color(0xFFD9534F),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: deepNavy,
  );

  static const ColorScheme _darkScheme = ColorScheme.dark(
    primary: Colors.white,
    onPrimary: midnight,
    secondary: Color(0xFF8FB4FF),
    onSecondary: midnight,
    error: Color(0xFFEF7272),
    onError: midnight,
    surface: midnightSurface,
    onSurface: Colors.white,
  );

  static const ColorScheme _accentScheme = ColorScheme.light(
    primary: accentPrimary,
    onPrimary: Colors.white,
    secondary: accentSecondary,
    onSecondary: Colors.white,
    error: Color(0xFFED5A65),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: accentSecondary,
  );
}
