import 'package:flutter/material.dart';

import '../domain/palette.dart';

const TextStyle tabularFigures = TextStyle(
  fontFeatures: [FontFeature.tabularFigures()],
);

/// 색 역할에 없는 앱 전용 색.
class SpendColors extends ThemeExtension<SpendColors> {
  const SpendColors({required this.warning, required this.track});

  final Color warning;
  final Color track;

  @override
  SpendColors copyWith({Color? warning, Color? track}) =>
      SpendColors(warning: warning ?? this.warning, track: track ?? this.track);

  @override
  SpendColors lerp(ThemeExtension<SpendColors>? other, double t) {
    if (other is! SpendColors) return this;
    return SpendColors(
      warning: Color.lerp(warning, other.warning, t)!,
      track: Color.lerp(track, other.track, t)!,
    );
  }
}

ThemeData buildAppTheme(AppThemeId id, Brightness brightness) {
  final colors = themeColors(id);
  final p = brightness == Brightness.dark ? colors.dark : colors.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Color(p.primary),
        brightness: brightness,
      ).copyWith(
        primary: Color(p.primary),
        surface: Color(p.background),
        onSurface: Color(p.onSurface),
        onSurfaceVariant: Color(p.subtle),
        surfaceContainer: Color(p.card),
        surfaceContainerHighest: Color(p.track),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [SpendColors(warning: Color(p.warning), track: Color(p.track))],
  );
}
