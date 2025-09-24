library core_app_shell;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Bootstraps a router based Flutter application in a consistent way.
Future<void> runSpiralRouterApp({
  required FutureOr<void> Function() bootstrap,
  required GoRouter router,
  BlocObserver? blocObserver,
  void Function(Object error, StackTrace stackTrace)? onError,
}) async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (blocObserver != null) {
      Bloc.observer = blocObserver;
    }

    await bootstrap();

    runApp(SpiralRouterApp(router: router));
  }, onError ?? (Object error, StackTrace stackTrace) {});
}

/// Stateless wrapper around [MaterialApp.router] configured with a [GoRouter].
class SpiralRouterApp extends StatelessWidget {
  final GoRouter router;
  final String? title;
  final ThemeData? theme;

  const SpiralRouterApp({
    super.key,
    required this.router,
    this.title,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: title,
      theme: theme,
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
    );
  }
}
