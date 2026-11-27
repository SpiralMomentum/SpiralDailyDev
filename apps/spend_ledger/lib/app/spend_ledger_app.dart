import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/budget/presentation/home_page.dart';
import '../features/ingest/domain/ingest.dart';
import '../features/ledger/presentation/candidates_page.dart';
import '../features/ledger/presentation/edit_page.dart';
import 'routes.dart';

/// 알림 응답처럼 위젯 밖에서 화면을 여는 데 쓴다.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// 거래 수정 화면을 연다. 앱이 아직 그려지지 않았으면 아무것도 하지 않는다.
void openEditPage(String id) =>
    appNavigatorKey.currentState?.pushNamed(AppRoutes.edit, arguments: id);

class SpendLedgerApp extends StatelessWidget {
  const SpendLedgerApp({super.key, required this.deps, this.initialEditId});

  final IngestDeps deps;

  /// 알림을 눌러 앱이 시작됐을 때 홈 위에 열 거래 id.
  final String? initialEditId;

  @override
  Widget build(BuildContext context) => RepositoryProvider<IngestDeps>.value(
    value: deps,
    child: MaterialApp(
      title: '지출 위젯',
      navigatorKey: appNavigatorKey,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      onGenerateRoute: _route,
      onGenerateInitialRoutes: (_) => [
        _route(const RouteSettings(name: AppRoutes.home)),
        if (initialEditId != null)
          _route(RouteSettings(name: AppRoutes.edit, arguments: initialEditId)),
      ],
    ),
  );
}

Route<void> _route(RouteSettings settings) => MaterialPageRoute<void>(
  settings: settings,
  builder: (_) => switch (settings.name) {
    AppRoutes.candidates => const CandidatesPage(),
    AppRoutes.edit => EditPage(id: settings.arguments! as String),
    AppRoutes.settings => const _SettingsPlaceholder(),
    _ => const HomePage(),
  },
);

/// 설정 화면은 다음 단계에서 만든다.
class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('설정')));
}
