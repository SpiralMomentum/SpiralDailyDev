import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/balance/domain/calendar_date.dart';
import '../features/balance/domain/profile.dart';
import '../features/balance/presentation/passbook_cubit.dart';
import '../features/balance/presentation/passbook_page.dart';
import '../features/life_table/data/life_table_parser.dart';
import '../features/ongoing_notification/data/midnight_scheduler.dart';
import '../features/ongoing_notification/data/ongoing_notifier.dart';
import '../features/profile/domain/profile_repository.dart';
import '../features/profile/domain/settings.dart';
import '../features/profile/presentation/onboarding/onboarding_cubit.dart';
import '../features/profile/presentation/onboarding/onboarding_page.dart';
import '../features/settings/presentation/settings_cubit.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/tone/domain/tone.dart';
import '../features/tone/domain/tone_table.dart';
import '../features/tone/presentation/tone_theme.dart';
import '../features/widget_sync/data/home_widget_sync.dart';
import 'di/service_locator.dart';

const appTitle = '인생잔고';
const _korean = Locale('ko', 'KR');

/// 앱 시작 시 번들에서 읽는 불변 데이터.
class AppAssets {
  const AppAssets({required this.table, required this.tones});

  final JsonLifeTable table;
  final Map<ToneId, ToneTable> tones;
}

ThemeMode themeModeFor(ThemePref pref) => switch (pref) {
  ThemePref.system => ThemeMode.system,
  ThemePref.light => ThemeMode.light,
  ThemePref.dark => ThemeMode.dark,
};

CalendarDate todayFromEnvironment() =>
    CalendarDate.fromDateTime(sl<AppEnvironment>().now());

/// 진행 중인 동기화의 끝. 다음 호출은 이 뒤에 이어 붙고, 모두 끝나면 null로 돌아간다.
Future<void>? _syncTail;

/// 위젯과 상시 알림을 현재 프로필/설정으로 맞춘다.
/// 설정을 빠르게 바꿔 호출이 겹쳐도 저장 키가 섞이거나 옛 설정이 마지막에
/// 쓰이지 않도록 호출 순서대로 하나씩 실행한다.
/// 플랫폼 호출 실패가 화면 진입을 막지 않도록 오류는 기록만 한다.
Future<void> syncOutputs(
  Profile profile,
  AppSettings settings,
  AppAssets assets,
) {
  final previous = _syncTail;
  final run = previous == null
      ? _syncOutputsNow(profile, settings, assets)
      : previous.then((_) => _syncOutputsNow(profile, settings, assets));
  final tail = run.catchError((Object _) {});
  _syncTail = tail;
  tail.whenComplete(() {
    if (identical(_syncTail, tail)) _syncTail = null;
  });
  return run;
}

Future<void> _syncOutputsNow(
  Profile profile,
  AppSettings settings,
  AppAssets assets,
) async {
  final tone = assets.tones[settings.tone];
  if (tone == null) return;
  try {
    await syncDerivedOutputs(
      profile: profile,
      settings: settings,
      table: assets.table,
      tone: tone,
      today: todayFromEnvironment(),
      widgets: sl<WidgetGateway>(),
      notifier: sl<OngoingNotifier>(),
    );
  } catch (e) {
    debugPrint('syncDerivedOutputs failed: $e');
  }
}

/// 자정/주기 갱신 작업을 예약한다. 실패해도 앱은 계속 동작한다.
Future<void> ensureRefreshScheduled() async {
  try {
    await sl<RefreshScheduler>().ensureScheduled(sl<AppEnvironment>().now());
  } catch (e) {
    debugPrint('ensureScheduled failed: $e');
  }
}

/// 생명표/말투를 읽지 못했을 때의 화면.
class LoadErrorApp extends StatelessWidget {
  const LoadErrorApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    title: appTitle,
    locale: _korean,
    supportedLocales: [_korean],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('데이터를 불러오지 못했습니다', textAlign: TextAlign.center),
          ),
        ),
      ),
    ),
  );
}

/// 온보딩과 통장/설정 화면을 묶는 루트 위젯.
/// 설정이 바뀌면 테마(말투 x 밝기)와 통장 상태를 즉시 다시 만들고,
/// 앱이 다시 보이면(resumed) 통장과 위젯/알림을 오늘 기준으로 갱신한다.
class LifeBalanceApp extends StatefulWidget {
  const LifeBalanceApp({
    super.key,
    required this.assets,
    required this.initialProfile,
    required this.initialSettings,
  });

  final AppAssets assets;
  final Profile? initialProfile;
  final AppSettings initialSettings;

  @override
  State<LifeBalanceApp> createState() => _LifeBalanceAppState();
}

class _LifeBalanceAppState extends State<LifeBalanceApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late Profile? _profile = widget.initialProfile;
  late AppSettings _settings = widget.initialSettings;
  OnboardingCubit? _onboarding;
  PassbookCubit? _passbook;

  /// 온보딩 저장이 끝나 완료 화면에 머무는 동안의 결과.
  (Profile, AppSettings)? _completed;

  AppAssets get _assets => widget.assets;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final profile = _profile;
    if (profile == null) {
      _onboarding = _newOnboarding();
    } else {
      _passbook = _newPassbook(profile, _settings);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _onboarding?.close();
    _passbook?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final profile = _profile;
    final passbook = _passbook;
    if (profile == null || passbook == null) return;
    passbook.refresh();
    syncOutputs(profile, _settings, _assets);
  }

  OnboardingCubit _newOnboarding() => OnboardingCubit(
    repo: sl<ProfileRepository>(),
    notifier: sl<OngoingNotifier>(),
    table: _assets.table,
    today: todayFromEnvironment,
    deviceCountry: sl<AppEnvironment>().deviceCountry(),
    onComplete: _onOnboardingComplete,
  );

  PassbookCubit _newPassbook(Profile profile, AppSettings settings) =>
      PassbookCubit(
        profile: profile,
        settings: settings,
        table: _assets.table,
        tone: _assets.tones[settings.tone]!,
        today: todayFromEnvironment,
      );

  Future<void> _onOnboardingComplete(
    Profile profile,
    AppSettings settings,
  ) async {
    _completed = (profile, settings);
    await syncOutputs(profile, settings, _assets);
    await ensureRefreshScheduled();
  }

  void _finishOnboarding() {
    final completed = _completed;
    if (completed == null) return;
    final (profile, settings) = completed;
    final onboarding = _onboarding;
    setState(() {
      _profile = profile;
      _settings = settings;
      _onboarding = null;
      _passbook = _newPassbook(profile, settings);
    });
    onboarding?.close();
  }

  Future<void> _onSettingsChanged(Profile profile, AppSettings settings) async {
    if (mounted) {
      final old = _passbook;
      setState(() {
        _profile = profile;
        _settings = settings;
        _passbook = _newPassbook(profile, settings);
      });
      await old?.close();
    }
    await syncOutputs(profile, settings, _assets);
  }

  Future<void> _openSettings() async {
    final profile = _profile;
    final navigator = _navigatorKey.currentState;
    if (profile == null || navigator == null) return;
    final cubit = SettingsCubit(
      repo: sl<ProfileRepository>(),
      notifier: sl<OngoingNotifier>(),
      today: todayFromEnvironment,
      initialProfile: profile,
      initialSettings: _settings,
      onChanged: _onSettingsChanged,
    );
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          cubit: cubit,
          countries: _assets.table.countries,
          table: _assets.table,
          tones: _assets.tones,
          today: todayFromEnvironment,
          pinner: sl(),
        ),
      ),
    );
    await cubit.close();
  }

  Widget _home() {
    final onboarding = _onboarding;
    if (onboarding != null) {
      return OnboardingPage(
        cubit: onboarding,
        countries: _assets.table.countries,
        tones: _assets.tones,
        today: todayFromEnvironment,
        pinner: sl(),
        onFinish: _finishOnboarding,
      );
    }
    return BlocProvider<PassbookCubit>.value(
      key: ObjectKey(_passbook),
      value: _passbook!,
      child: PassbookPage(
        config: sl(),
        tone: _assets.tones[_settings.tone]!,
        onOpenSettings: _openSettings,
        opener: sl(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tone = _settings.tone;
    return MaterialApp(
      title: appTitle,
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      locale: _korean,
      supportedLocales: const [_korean],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: themeFor(tone, Brightness.light),
      darkTheme: themeFor(tone, Brightness.dark),
      themeMode: themeModeFor(_settings.themePref),
      home: _home(),
    );
  }
}
