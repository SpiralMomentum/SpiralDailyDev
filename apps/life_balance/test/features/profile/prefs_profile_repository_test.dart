import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/balance/domain/balance_format.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/profile/data/prefs_profile_repository.dart';
import 'package:life_balance/features/profile/domain/settings.dart';
import 'package:life_balance/features/tone/domain/tone.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<PrefsProfileRepository> _repo([
  Map<String, Object> init = const {},
]) async {
  SharedPreferences.setMockInitialValues(init);
  return PrefsProfileRepository(await SharedPreferences.getInstance());
}

void main() {
  const base = Profile(
    birthDate: CalendarDate(1990, 2, 28),
    sex: Sex.female,
    countryCode: 'KR',
  );

  test('loadProfile is null before save', () async {
    expect(await (await _repo()).loadProfile(), isNull);
  });

  test('profile roundtrip with null manual lifespan', () async {
    final r = await _repo();
    await r.saveProfile(base);
    expect(await r.loadProfile(), base);
  });

  test('profile roundtrip with manual 80.5, then cleared', () async {
    final r = await _repo();
    final p = base.copyWith(manualLifespanYears: 80.5);
    await r.saveProfile(p);
    expect(await r.loadProfile(), p);
    await r.saveProfile(base);
    expect((await r.loadProfile())!.manualLifespanYears, isNull);
  });

  test('settings defaults', () async {
    expect(await (await _repo()).loadSettings(), AppSettings.defaults);
    expect(AppSettings.defaults.unit, BalanceUnit.days);
    expect(AppSettings.defaults.tone, ToneId.stoic);
    expect(AppSettings.defaults.themePref, ThemePref.system);
    expect(AppSettings.defaults.ongoingNotification, isTrue);
  });

  test('settings roundtrip', () async {
    final r = await _repo();
    const s = AppSettings(
      unit: BalanceUnit.percent,
      tone: ToneId.community,
      themePref: ThemePref.dark,
      ongoingNotification: false,
    );
    await r.saveSettings(s);
    expect(await r.loadSettings(), s);
  });

  test('unknown enum strings fall back to defaults', () async {
    final r = await _repo({
      'lb.unit': 'bogus',
      'lb.tone': 'x',
      'lb.themePref': '?',
    });
    expect(await r.loadSettings(), AppSettings.defaults);
  });

  test('unknown sex string yields null profile', () async {
    final r = await _repo({
      'lb.birthDate': '1990-02-28',
      'lb.sex': 'zzz',
      'lb.countryCode': 'KR',
    });
    expect(await r.loadProfile(), isNull);
  });
}
