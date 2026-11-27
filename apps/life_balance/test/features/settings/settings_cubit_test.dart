import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/balance/domain/balance_format.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/balance/domain/profile.dart';
import 'package:life_balance/features/ongoing_notification/data/ongoing_notifier.dart';
import 'package:life_balance/features/profile/domain/profile_repository.dart';
import 'package:life_balance/features/profile/domain/settings.dart';
import 'package:life_balance/features/settings/presentation/settings_cubit.dart';
import 'package:life_balance/features/tone/domain/tone.dart';
import 'package:mocktail/mocktail.dart';

class MockRepo extends Mock implements ProfileRepository {}

class FakeNotifier implements OngoingNotifier {
  FakeNotifier(this.granted);
  final bool granted;
  int calls = 0;
  @override
  Future<bool> requestPermission() async {
    calls++;
    return granted;
  }

  @override
  Future<void> show(String text) async {}
  @override
  Future<void> cancel() async {}
}

const _today = CalendarDate(2026, 6, 15);
const _profile = Profile(
  birthDate: CalendarDate(1990, 1, 1),
  sex: Sex.male,
  countryCode: 'KR',
  manualLifespanYears: 90,
);

void main() {
  late MockRepo repo;
  late List<(Profile, AppSettings)> changes;

  setUpAll(() {
    registerFallbackValue(_profile);
    registerFallbackValue(AppSettings.defaults);
  });

  setUp(() {
    repo = MockRepo();
    changes = [];
    when(() => repo.saveProfile(any())).thenAnswer((_) async {});
    when(() => repo.saveSettings(any())).thenAnswer((_) async {});
  });

  SettingsCubit make({
    bool granted = true,
    AppSettings settings = AppSettings.defaults,
    Profile profile = _profile,
    FakeNotifier? notifier,
  }) => SettingsCubit(
    repo: repo,
    notifier: notifier ?? FakeNotifier(granted),
    today: () => _today,
    initialProfile: profile,
    initialSettings: settings,
    onChanged: (p, s) async => changes.add((p, s)),
  );

  test('updateProfile saves, notifies, emits', () async {
    final c = make();
    final next = _profile.copyWith(sex: Sex.female);
    await c.updateProfile(next);
    verify(() => repo.saveProfile(next)).called(1);
    expect(changes.single.$1, next);
    expect(c.state.profile, next);
  });

  test('future birth date rejected, nothing saved', () async {
    final c = make();
    await c.updateProfile(
      _profile.copyWith(birthDate: const CalendarDate(2026, 6, 16)),
    );
    verifyNever(() => repo.saveProfile(any()));
    expect(changes, isEmpty);
    expect(c.state.error, SettingsError.futureBirthDate);
    expect(c.state.profile, _profile);
  });

  test('setUnit/setTone/setThemePref save and notify', () async {
    final c = make();
    await c.setUnit(BalanceUnit.weeks);
    await c.setTone(ToneId.wit);
    await c.setThemePref(ThemePref.dark);
    expect(c.state.settings.unit, BalanceUnit.weeks);
    expect(c.state.settings.tone, ToneId.wit);
    expect(c.state.settings.themePref, ThemePref.dark);
    verify(() => repo.saveSettings(any())).called(3);
    expect(changes.length, 3);
    expect(changes.last.$2.themePref, ThemePref.dark);
  });

  test('save failure emits saveFailed and does not notify', () async {
    when(() => repo.saveSettings(any())).thenThrow(Exception('x'));
    final c = make();
    await c.setUnit(BalanceUnit.years);
    expect(c.state.error, SettingsError.saveFailed);
    expect(c.state.settings.unit, BalanceUnit.days);
    expect(changes, isEmpty);
  });

  test('manual -> auto clears manualLifespanYears', () async {
    final c = make();
    await c.setManualLifespan(null);
    expect(c.state.profile.manualLifespanYears, isNull);
    expect(changes.single.$1.manualLifespanYears, isNull);
  });

  test('valid manual lifespan saved, including below current age', () async {
    final c = make();
    await c.setManualLifespan(20);
    expect(c.state.profile.manualLifespanYears, 20);
    expect(changes.single.$1.manualLifespanYears, 20);
    expect(c.state.error, isNull);
  });

  test('invalid manual lifespan not saved, error set', () async {
    for (final v in [0.0, -1.0, 151.0, double.nan, double.infinity]) {
      final c = make();
      await c.setManualLifespan(v);
      expect(c.state.error, SettingsError.invalidLifespan, reason: '$v');
      expect(c.state.profile, _profile);
    }
    verifyNever(() => repo.saveProfile(any()));
    expect(changes, isEmpty);
  });

  test('valid input after invalid clears error', () async {
    final c = make();
    await c.setManualLifespan(double.nan);
    await c.setManualLifespan(85);
    expect(c.state.error, isNull);
    expect(c.state.profile.manualLifespanYears, 85);
  });

  test('setOngoing(true) granted saves true', () async {
    final n = FakeNotifier(true);
    final c = make(
      notifier: n,
      settings: AppSettings.defaults.copyWith(ongoingNotification: false),
    );
    await c.setOngoing(true);
    expect(n.calls, 1);
    expect(c.state.settings.ongoingNotification, isTrue);
    expect(c.state.permissionDenied, isFalse);
    expect(changes.single.$2.ongoingNotification, isTrue);
  });

  test('setOngoing(true) denied keeps false and flags permissionDenied',
      () async {
    final c = make(
      granted: false,
      settings: AppSettings.defaults.copyWith(ongoingNotification: false),
    );
    await c.setOngoing(true);
    expect(c.state.settings.ongoingNotification, isFalse);
    expect(c.state.permissionDenied, isTrue);
    verifyNever(() => repo.saveSettings(any()));
    expect(changes, isEmpty);
  });

  test('setOngoing(false) saves, notifies, no permission request', () async {
    final n = FakeNotifier(true);
    final c = make(notifier: n);
    await c.setOngoing(false);
    expect(n.calls, 0);
    expect(c.state.settings.ongoingNotification, isFalse);
    expect(changes.single.$2.ongoingNotification, isFalse);
  });
}
