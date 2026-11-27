import 'package:shared_preferences/shared_preferences.dart';

import '../../balance/domain/balance_format.dart';
import '../../balance/domain/calendar_date.dart';
import '../../balance/domain/profile.dart';
import '../../tone/domain/tone.dart';
import '../domain/profile_repository.dart';
import '../domain/settings.dart';

class PrefsProfileRepository implements ProfileRepository {
  PrefsProfileRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _birth = 'lb.birthDate';
  static const _sex = 'lb.sex';
  static const _country = 'lb.countryCode';
  static const _manual = 'lb.manualLifespanYears';
  static const _unit = 'lb.unit';
  static const _tone = 'lb.tone';
  static const _theme = 'lb.themePref';
  static const _ongoing = 'lb.ongoingNotification';

  static T? _byName<T extends Enum>(List<T> values, String? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  @override
  Future<Profile?> loadProfile() async {
    final birthRaw = _prefs.getString(_birth);
    final sex = _byName(Sex.values, _prefs.getString(_sex));
    final country = _prefs.getString(_country);
    if (birthRaw == null || sex == null || country == null) return null;
    try {
      return Profile(
        birthDate: CalendarDate.parse(birthRaw),
        sex: sex,
        countryCode: country,
        manualLifespanYears: _prefs.getDouble(_manual),
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> saveProfile(Profile p) async {
    await _prefs.setString(_birth, p.birthDate.toIso());
    await _prefs.setString(_sex, p.sex.name);
    await _prefs.setString(_country, p.countryCode);
    final manual = p.manualLifespanYears;
    if (manual == null) {
      await _prefs.remove(_manual);
    } else {
      await _prefs.setDouble(_manual, manual);
    }
  }

  @override
  Future<AppSettings> loadSettings() async => AppSettings(
    unit:
        _byName(BalanceUnit.values, _prefs.getString(_unit)) ??
        AppSettings.defaults.unit,
    tone:
        _byName(ToneId.values, _prefs.getString(_tone)) ??
        AppSettings.defaults.tone,
    themePref:
        _byName(ThemePref.values, _prefs.getString(_theme)) ??
        AppSettings.defaults.themePref,
    ongoingNotification:
        _prefs.getBool(_ongoing) ?? AppSettings.defaults.ongoingNotification,
  );

  @override
  Future<void> saveSettings(AppSettings s) async {
    await _prefs.setString(_unit, s.unit.name);
    await _prefs.setString(_tone, s.tone.name);
    await _prefs.setString(_theme, s.themePref.name);
    await _prefs.setBool(_ongoing, s.ongoingNotification);
  }
}
