import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';

import '../features/budget/presentation/home_page.dart';
import '../features/ingest/domain/ingest.dart';
import '../features/ledger/presentation/candidates_page.dart';
import '../features/ledger/presentation/edit_page.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/settings/presentation/settings_cubit.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/theme/domain/palette.dart';
import '../features/theme/presentation/app_theme.dart';
import 'routes.dart';

/// 알림 응답처럼 위젯 밖에서 화면을 여는 데 쓴다.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// 거래 수정 화면을 연다. 앱이 아직 그려지지 않았으면 아무것도 하지 않는다.
void openEditPage(String id) =>
    appNavigatorKey.currentState?.pushNamed(AppRoutes.edit, arguments: id);

/// 위젯 탭 URI가 가리키는 라우트. 모르는 주소면 null(아무것도 하지 않는다).
String? routeForWidgetUri(Uri? uri) => switch (uri?.host) {
  'candidates' => AppRoutes.candidates,
  'home' => AppRoutes.home,
  _ => null,
};

void _openWidgetUri(Uri? uri) {
  final route = routeForWidgetUri(uri);
  final nav = appNavigatorKey.currentState;
  if (route == null || nav == null) return;
  if (route == AppRoutes.home) {
    nav.popUntil((r) => r.isFirst);
  } else {
    nav.pushNamed(route);
  }
}

class SpendLedgerApp extends StatefulWidget {
  const SpendLedgerApp({
    super.key,
    required this.deps,
    this.initialEditId,
    this.listenWidgetClicks = false,
    this.initialWidgetUri,
    this.initialSettings,
  });

  final IngestDeps deps;

  /// 알림을 눌러 앱이 시작됐을 때 홈 위에 열 거래 id.
  final String? initialEditId;

  /// 위젯 탭을 받을지. 테스트에서는 플랫폼 채널이 없어 끈다.
  final bool listenWidgetClicks;

  /// 위젯 탭으로 시작됐는지 알려 주는 원천. 비우면 [listenWidgetClicks]일 때 home_widget을 쓴다.
  final Future<Uri?> Function()? initialWidgetUri;

  /// 첫 프레임부터 저장된 테마로 그리기 위한 시작 설정.
  /// 읽지 못했으면 null. 기본값으로 그리고 설정을 다시 읽는다.
  final AppSettings? initialSettings;

  @override
  State<SpendLedgerApp> createState() => _SpendLedgerAppState();
}

class _SpendLedgerAppState extends State<SpendLedgerApp> {
  StreamSubscription<Uri?>? _clicks;
  late final SettingsCubit _settings = SettingsCubit(
    widget.deps.settings,
    () => refreshOutputs(widget.deps),
    initial: widget.initialSettings,
  );

  @override
  void initState() {
    super.initState();
    if (widget.initialSettings == null) _settings.load();
    if (widget.listenWidgetClicks) {
      _clicks = HomeWidget.widgetClicked.listen(
        _openWidgetUri,
        onError: (Object e) =>
            debugPrint('widget click failed: ${e.runtimeType}'),
      );
    }
    final initial =
        widget.initialWidgetUri ??
        (widget.listenWidgetClicks
            ? HomeWidget.initiallyLaunchedFromHomeWidget
            : null);
    // 앱이 위젯 탭으로 시작된 경우다.
    initial?.call().then(
      _openWhenReady,
      onError: (Object e) =>
          debugPrint('initial widget uri failed: ${e.runtimeType}'),
    );
  }

  /// 내비게이터가 있으면 바로, 없으면 다음 프레임에 연다(프레임을 예약한다).
  void _openWhenReady(Uri? uri) {
    if (!mounted) return;
    if (appNavigatorKey.currentState != null) {
      _openWidgetUri(uri);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _openWidgetUri(uri));
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void dispose() {
    _clicks?.cancel();
    _settings.close();
    super.dispose();
  }

  IngestDeps get deps => widget.deps;
  String? get initialEditId => widget.initialEditId;

  @override
  Widget build(BuildContext context) => RepositoryProvider<IngestDeps>.value(
    value: deps,
    child: BlocProvider<SettingsCubit>.value(
      value: _settings,
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (a, b) =>
            a.settings.themeId != b.settings.themeId ||
            a.settings.themeMode != b.settings.themeMode,
        builder: (context, state) {
          final id = state.settings.themeId;
          return MaterialApp(
            title: '지출 위젯',
            navigatorKey: appNavigatorKey,
            theme: buildAppTheme(id, Brightness.light),
            darkTheme: buildAppTheme(id, Brightness.dark),
            themeMode: switch (state.settings.themeMode) {
              AppThemeMode.system => ThemeMode.system,
              AppThemeMode.light => ThemeMode.light,
              AppThemeMode.dark => ThemeMode.dark,
            },
            locale: const Locale('ko'),
            supportedLocales: const [Locale('ko')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            onGenerateRoute: _route,
            onGenerateInitialRoutes: (_) => [
              _route(const RouteSettings(name: AppRoutes.home)),
              if (initialEditId != null)
                _route(
                  RouteSettings(name: AppRoutes.edit, arguments: initialEditId),
                ),
            ],
          );
        },
      ),
    ),
  );
}

Route<void> _route(RouteSettings settings) => MaterialPageRoute<void>(
  settings: settings,
  builder: (_) => switch (settings.name) {
    AppRoutes.candidates => const CandidatesPage(),
    AppRoutes.edit => EditPage(id: settings.arguments! as String),
    AppRoutes.settings => const SettingsPage(),
    _ => const HomePage(),
  },
);
