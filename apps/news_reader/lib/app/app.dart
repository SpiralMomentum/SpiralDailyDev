import 'package:apps.news_reader/app/di/service_locator.dart';
import 'package:apps.news_reader/app/route/app_router.dart';
import 'package:apps.news_reader/features/settings/domain/entities/user_preferences.dart';
import 'package:apps.news_reader/features/settings/domain/usecases/get_settings.dart';
import 'package:apps.news_reader/features/settings/domain/usecases/update_settings.dart';
import 'package:apps.news_reader/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:apps.news_reader/features/settings/presentation/cubit/settings_state.dart';
import 'package:apps.news_reader/l10n/app_localizations.dart';
import 'package:apps.news_reader/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatelessWidget {
  const App({super.key, required this.initialLocation});

  final String initialLocation;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(
        getSettings: getIt.get<GetSettings>(),
        updateSettings: getIt.get<UpdateSettings>(),
      )..loadSettings(),
      child: _AppView(initialLocation: initialLocation),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView({required this.initialLocation});

  final String initialLocation;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.preferences.themeMode != curr.preferences.themeMode ||
          prev.preferences.locale != curr.preferences.locale,
      builder: (context, state) {
        final router = createRouter(initialLocation: initialLocation);
        final locale = state.preferences.locale == AppLocale.en
            ? const Locale('en')
            : const Locale('ko');

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: state.preferences.themeMode,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        );
      },
    );
  }
}
