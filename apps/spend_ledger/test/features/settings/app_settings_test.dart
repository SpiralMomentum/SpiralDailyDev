import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/settings/domain/app_settings.dart';
import 'package:spend_ledger/features/theme/domain/palette.dart';

void main() {
  test('테마 키 없는 기존 JSON은 남색·시스템', () {
    final s = AppSettings.fromJson({'startDay': 5});
    expect(s.themeId, AppThemeId.navy);
    expect(s.themeMode, AppThemeMode.system);
    expect(s.startDay, 5);
  });
  test('JSON 왕복', () {
    const s = AppSettings(
      themeId: AppThemeId.beige,
      themeMode: AppThemeMode.dark,
    );
    expect(AppSettings.fromJson(s.toJson()), s);
    expect(s.toJson()['themeId'], 'beige');
    expect(s.toJson()['themeMode'], 'dark');
  });
  test('모르는 값은 기본값', () {
    final s = AppSettings.fromJson({'themeId': 'teal', 'themeMode': 1});
    expect(s.themeId, AppThemeId.navy);
    expect(s.themeMode, AppThemeMode.system);
  });
}
