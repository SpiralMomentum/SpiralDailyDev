import 'package:apps.daily_memo/presentation/app_routes.dart';
import 'package:apps.daily_memo/presentation/routes_impl/app_routes_go_router.dart';
import 'package:apps.daily_memo/presentation/routes_impl/app_routes_modular.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:go_router/go_router.dart';

void main() {
  // Modular Main Setting
  // runApp(ModularApp(module: AppRoutesModuler(), child: const MyApp()));

  // Default Main Setting
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    /*
    // GoRouter Setting
    // final router =
    //     GoRouter(routes: AppRoutes.values.map((e) => e.getRouter).toList());
    // return MaterialApp.router(
    //   routeInformationProvider: router.routeInformationProvider,
    //   routeInformationParser: router.routeInformationParser,
    //   routerDelegate: router.routerDelegate,
    // );
     */

    // Modular Setting
    return MaterialApp.router(
      routeInformationParser: Modular.routeInformationParser,
      routerDelegate: Modular.routerDelegate,
    );
  }
}
