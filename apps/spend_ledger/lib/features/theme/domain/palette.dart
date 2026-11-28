import 'dart:math' as math;

enum AppThemeId {
  navy('남색'),
  beige('베이지');

  const AppThemeId(this.label);

  /// 화면에 보이는 이름.
  final String label;

  static AppThemeId fromName(String? name) => AppThemeId.values.firstWhere(
    (e) => e.name == name,
    orElse: () => AppThemeId.navy,
  );
}

enum AppThemeMode {
  system,
  light,
  dark;

  static AppThemeMode fromName(String? name) => AppThemeMode.values.firstWhere(
    (e) => e.name == name,
    orElse: () => AppThemeMode.system,
  );
}

/// 한 테마의 한 밝기에 쓰는 색 8개 (ARGB int).
final class Palette {
  const Palette({
    required this.background,
    required this.onSurface,
    required this.subtle,
    required this.primary,
    required this.track,
    required this.card,
    required this.widgetBackground,
    required this.warning,
  });

  final int background;
  final int onSurface;
  final int subtle;
  final int primary;
  final int track;
  final int card;
  final int widgetBackground;
  final int warning;
}

final class ThemeColors {
  const ThemeColors({required this.light, required this.dark});

  final Palette light;
  final Palette dark;
}

const _navy = ThemeColors(
  light: Palette(
    background: 0xFFF7F8FC,
    onSurface: 0xFF171B24,
    subtle: 0xFF4C5468,
    primary: 0xFF2F4A7A,
    track: 0xFFD6DEEE,
    card: 0xFFE6EBF5,
    widgetBackground: 0xFFFFFFFF,
    warning: 0xFFC2410C,
  ),
  dark: Palette(
    background: 0xFF10131A,
    onSurface: 0xFFE0E3EC,
    subtle: 0xFFA3ABBE,
    primary: 0xFF9DB8F0,
    track: 0xFF232B3D,
    card: 0xFF1B2130,
    widgetBackground: 0xFF181D29,
    warning: 0xFFFDBA74,
  ),
);

const _beige = ThemeColors(
  light: Palette(
    background: 0xFFFBF7F1,
    onSurface: 0xFF221B15,
    subtle: 0xFF6B5A4B,
    primary: 0xFF9A5230,
    track: 0xFFF0DCCB,
    card: 0xFFF3E9DD,
    widgetBackground: 0xFFFFFDF9,
    warning: 0xFFB42318,
  ),
  dark: Palette(
    background: 0xFF18130F,
    onSurface: 0xFFEDE0D4,
    subtle: 0xFFBCA897,
    primary: 0xFFF0A77A,
    track: 0xFF3A2A1F,
    card: 0xFF251D17,
    widgetBackground: 0xFF201913,
    warning: 0xFFFFB4A8,
  ),
);

ThemeColors themeColors(AppThemeId id) => switch (id) {
  AppThemeId.navy => _navy,
  AppThemeId.beige => _beige,
};

double _luminance(int argb) {
  double channel(int shift) {
    final c = ((argb >> shift) & 0xFF) / 255;
    return c <= 0.03928
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4) as double;
  }

  return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0);
}

/// WCAG 2.x 대비. 1 이상 21 이하.
double contrastRatio(int argbA, int argbB) {
  final a = _luminance(argbA);
  final b = _luminance(argbB);
  final hi = math.max(a, b);
  final lo = math.min(a, b);
  return (hi + 0.05) / (lo + 0.05);
}
