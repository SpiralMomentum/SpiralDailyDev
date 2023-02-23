import 'package:exchange_rate_calculator/presentation/core/navigation/routes/app_routes.dart';
import 'package:exchange_rate_calculator/presentation/core/navigation/routes/app_routes_go_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router =
    GoRouter(routes: AppRoutes.values.map((e) => e.getRouter).toList());
    return MaterialApp.router(
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
    );
  }
}