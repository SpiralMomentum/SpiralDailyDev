import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/tone.dart';

class TonePalette {
  const TonePalette({
    required this.background,
    required this.foreground,
    required this.accent,
    required this.surface,
  });

  final Color background;
  final Color foreground;
  final Color accent;
  final Color surface;
}

const _bodyFamily = 'Pretendard';

TonePalette paletteFor(ToneId tone, Brightness b) {
  final light = b == Brightness.light;
  switch (tone) {
    case ToneId.stoic:
      return light
          ? const TonePalette(
              background: Color(0xFFF6F1E7),
              foreground: Color(0xFF2B2B2B),
              accent: Color(0xFFB08D57),
              surface: Color(0xFFEDE6D6),
            )
          : const TonePalette(
              background: Color(0xFF1E1B16),
              foreground: Color(0xFFEDE6D6),
              accent: Color(0xFFB08D57),
              surface: Color(0xFF2A261F),
            );
    case ToneId.wit:
      return light
          ? const TonePalette(
              background: Color(0xFFFFF4F0),
              foreground: Color(0xFF3A3A3A),
              accent: Color(0xFFFF7F6E),
              surface: Color(0xFFFFE6DF),
            )
          : const TonePalette(
              background: Color(0xFF2A1F1D),
              foreground: Color(0xFFFFEDE8),
              accent: Color(0xFFFF7F6E),
              surface: Color(0xFF382927),
            );
    case ToneId.community:
      return light
          ? const TonePalette(
              background: Color(0xFFFFFFFF),
              foreground: Color(0xFF111111),
              accent: Color(0xFF3B5BDB),
              surface: Color(0xFFF2F3F5),
            )
          : const TonePalette(
              background: Color(0xFF121212),
              foreground: Color(0xFFF2F3F5),
              accent: Color(0xFF3B5BDB),
              surface: Color(0xFF1E1F22),
            );
  }
}

String _headingFamily(ToneId tone) => switch (tone) {
      ToneId.stoic => 'StoicSerif',
      ToneId.wit => 'WitRounded',
      ToneId.community => _bodyFamily,
    };

ThemeData themeFor(ToneId tone, Brightness b) {
  final p = paletteFor(tone, b);
  final heading = _headingFamily(tone);
  // WitRounded(Jua)는 Regular 한 굵기뿐이라 합성 굵기를 피한다.
  final headingWeight = tone == ToneId.wit ? FontWeight.w400 : FontWeight.w700;

  final base = ThemeData(
    brightness: b,
    useMaterial3: true,
    fontFamily: _bodyFamily,
    scaffoldBackgroundColor: p.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: b,
    ).copyWith(
      surface: p.background,
      onSurface: p.foreground,
      primary: p.accent,
      surfaceContainerHighest: p.surface,
    ),
  );

  TextStyle h(TextStyle? s) => (s ?? const TextStyle()).copyWith(
        fontFamily: heading,
        fontWeight: headingWeight,
        color: p.foreground,
      );

  final t = base.textTheme.apply(
    fontFamily: _bodyFamily,
    bodyColor: p.foreground,
    displayColor: p.foreground,
  );

  // 통장 AppBar는 투명이라 상태 표시줄 아이콘을 배경 밝기의 반대로 맞춘다.
  final overlay = b == Brightness.light
      ? SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        )
      : SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        );

  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(systemOverlayStyle: overlay),
    textTheme: t.copyWith(
      displayLarge: h(t.displayLarge).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      displayMedium: h(t.displayMedium),
      displaySmall: h(t.displaySmall),
      headlineLarge: h(t.headlineLarge),
      headlineMedium: h(t.headlineMedium),
      headlineSmall: h(t.headlineSmall),
      titleLarge: h(t.titleLarge),
    ),
  );
}
