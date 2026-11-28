import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/theme/domain/palette.dart';
import 'package:spend_ledger/features/theme/presentation/app_theme.dart';

void main() {
  test('buildAppTheme은 색 표를 따른다', () {
    final t = buildAppTheme(AppThemeId.beige, Brightness.dark);
    final p = themeColors(AppThemeId.beige).dark;
    expect(t.brightness, Brightness.dark);
    expect(t.colorScheme.primary, Color(p.primary));
    expect(t.colorScheme.surface, Color(p.background));
    expect(t.colorScheme.onSurface, Color(p.onSurface));
    expect(t.colorScheme.onSurfaceVariant, Color(p.subtle));
    expect(t.colorScheme.surfaceContainer, Color(p.card));
    expect(t.extension<SpendColors>()!.warning, Color(p.warning));
    expect(t.extension<SpendColors>()!.track, Color(p.track));
  });

  test('자동 생성 보조 색 대신 색 표 값을 쓴다(카드·컨테이너·진행 막대 바탕)', () {
    for (final id in AppThemeId.values) {
      for (final b in Brightness.values) {
        final t = buildAppTheme(id, b);
        final c = themeColors(id);
        final p = b == Brightness.dark ? c.dark : c.light;
        final s = t.colorScheme;
        for (final card in [
          s.surfaceContainerLowest,
          s.surfaceContainerLow,
          s.surfaceContainer,
          s.surfaceContainerHigh,
        ]) {
          expect(card, Color(p.card), reason: '$id $b');
        }
        expect(s.surfaceContainerHighest, Color(p.track), reason: '$id $b');
        expect(s.secondaryContainer, Color(p.track), reason: '$id $b');
        expect(s.primaryContainer, Color(p.track), reason: '$id $b');
        expect(s.onPrimaryContainer, Color(p.onSurface), reason: '$id $b');
        expect(s.onSecondaryContainer, Color(p.onSurface), reason: '$id $b');
      }
    }
  });
}
