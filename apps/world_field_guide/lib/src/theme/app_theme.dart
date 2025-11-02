import 'package:flutter/material.dart';

abstract class AppTheme {
  static const Color primaryBlue = Color(0xFF1390F1);
  static const Color deepNavy = Color(0xFF0B3F6A);
  static const Color paleSky = Color(0xFFF1F7FF);
  static const Color mapCanvas = Color(0xFFE3F1FF);
  static const Color textSecondary = Color(0xFF5C708D);

  static ThemeData get light {
    final base = ThemeData.from(colorScheme: _colorScheme, useMaterial3: true);
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

  static const ColorScheme _colorScheme = ColorScheme.light(
    primary: primaryBlue,
    onPrimary: Colors.white,
    secondary: deepNavy,
    onSecondary: Colors.white,
    error: Color(0xFFD9534F),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: deepNavy,
  );
}
