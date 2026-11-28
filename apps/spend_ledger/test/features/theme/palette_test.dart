import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/theme/domain/palette.dart';

void main() {
  test('설계 4절 색 표 32개 값', () {
    final navyLight = themeColors(AppThemeId.navy).light;
    expect(navyLight.background, 0xFFF7F8FC);
    expect(navyLight.onSurface, 0xFF171B24);
    expect(navyLight.subtle, 0xFF4C5468);
    expect(navyLight.primary, 0xFF2F4A7A);
    expect(navyLight.track, 0xFFD6DEEE);
    expect(navyLight.card, 0xFFE6EBF5);
    expect(navyLight.widgetBackground, 0xFFFFFFFF);
    expect(navyLight.warning, 0xFFC2410C);
    final navyDark = themeColors(AppThemeId.navy).dark;
    expect(navyDark.background, 0xFF10131A);
    expect(navyDark.onSurface, 0xFFE0E3EC);
    expect(navyDark.subtle, 0xFFA3ABBE);
    expect(navyDark.primary, 0xFF9DB8F0);
    expect(navyDark.track, 0xFF232B3D);
    expect(navyDark.card, 0xFF1B2130);
    expect(navyDark.widgetBackground, 0xFF181D29);
    expect(navyDark.warning, 0xFFFDBA74);
    final beigeLight = themeColors(AppThemeId.beige).light;
    expect(beigeLight.background, 0xFFFBF7F1);
    expect(beigeLight.onSurface, 0xFF221B15);
    expect(beigeLight.subtle, 0xFF6B5A4B);
    expect(beigeLight.primary, 0xFF9A5230);
    expect(beigeLight.track, 0xFFF0DCCB);
    expect(beigeLight.card, 0xFFF3E9DD);
    expect(beigeLight.widgetBackground, 0xFFFFFDF9);
    expect(beigeLight.warning, 0xFFB42318);
    final beigeDark = themeColors(AppThemeId.beige).dark;
    expect(beigeDark.background, 0xFF18130F);
    expect(beigeDark.onSurface, 0xFFEDE0D4);
    expect(beigeDark.subtle, 0xFFBCA897);
    expect(beigeDark.primary, 0xFFF0A77A);
    expect(beigeDark.track, 0xFF3A2A1F);
    expect(beigeDark.card, 0xFF251D17);
    expect(beigeDark.widgetBackground, 0xFF201913);
    expect(beigeDark.warning, 0xFFFFB4A8);
  });

  test('남색 밝음 primary와 베이지 밝음 primary', () {
    expect(themeColors(AppThemeId.navy).light.primary, 0xFF2F4A7A);
    expect(themeColors(AppThemeId.beige).light.primary, 0xFF9A5230);
  });

  test('모든 글자 토큰은 배경·위젯 배경 대비 4.5 이상', () {
    for (final id in AppThemeId.values) {
      final c = themeColors(id);
      for (final p in [c.light, c.dark]) {
        for (final fg in [p.onSurface, p.subtle, p.primary, p.warning]) {
          expect(contrastRatio(fg, p.background), greaterThanOrEqualTo(4.5));
          expect(
            contrastRatio(fg, p.widgetBackground),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    }
  });

  test('contrastRatio 흑백은 21', () {
    expect(contrastRatio(0xFF000000, 0xFFFFFFFF), closeTo(21, 0.01));
  });

  test('fromName 기본값과 label', () {
    expect(AppThemeId.fromName(null), AppThemeId.navy);
    expect(AppThemeId.fromName('teal'), AppThemeId.navy);
    expect(AppThemeId.fromName('beige'), AppThemeId.beige);
    expect(AppThemeMode.fromName('dark'), AppThemeMode.dark);
    expect(AppThemeMode.fromName('x'), AppThemeMode.system);
    expect(AppThemeId.navy.label, '남색');
    expect(AppThemeId.beige.label, '베이지');
  });
}
