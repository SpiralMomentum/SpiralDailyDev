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
}
