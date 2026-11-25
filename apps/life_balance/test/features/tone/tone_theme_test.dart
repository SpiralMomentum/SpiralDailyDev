import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/tone/domain/tone.dart';
import 'package:life_balance/features/tone/presentation/tone_theme.dart';

double _lin(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double luminance(Color c) =>
    0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b);

double contrast(Color a, Color b) {
  final la = luminance(a), lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final tone in ToneId.values) {
    for (final b in Brightness.values) {
      test('${tone.name}/${b.name} fg/bg contrast >= 4.5', () {
        final p = paletteFor(tone, b);
        expect(contrast(p.foreground, p.background), greaterThanOrEqualTo(4.5));
        expect(contrast(p.foreground, p.surface), greaterThanOrEqualTo(4.5));
      });

      test('${tone.name}/${b.name} theme fonts', () {
        final t = themeFor(tone, b);
        expect(t.brightness, b);
        expect(t.textTheme.bodyMedium!.fontFamily, 'Pretendard');
        expect(t.textTheme.displayLarge!.fontFeatures,
            contains(const FontFeature.tabularFigures()));
      });
    }
  }

  test('title/display font per tone', () {
    String? d(ToneId t) =>
        themeFor(t, Brightness.light).textTheme.displayLarge!.fontFamily;
    String? h(ToneId t) =>
        themeFor(t, Brightness.light).textTheme.titleLarge!.fontFamily;
    expect(d(ToneId.stoic), 'StoicSerif');
    expect(d(ToneId.wit), 'WitRounded');
    expect(d(ToneId.community), 'Pretendard');
    expect(h(ToneId.stoic), 'StoicSerif');
    expect(h(ToneId.wit), 'WitRounded');
    expect(h(ToneId.community), 'Pretendard');
  });

  test('light base colors', () {
    expect(paletteFor(ToneId.stoic, Brightness.light).background,
        const Color(0xFFF6F1E7));
    expect(paletteFor(ToneId.wit, Brightness.light).accent,
        const Color(0xFFFF7F6E));
    expect(paletteFor(ToneId.community, Brightness.light).surface,
        const Color(0xFFF2F3F5));
  });
}
