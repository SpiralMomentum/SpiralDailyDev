import 'package:apps.daily_memo/data/sql_helper.dart';
import 'package:apps.daily_memo/presentation/core/route/app_routes.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_impl/app_routes_modular.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:go_router/go_router.dart';

void main() async {

  // Default Main Setting
  WidgetsFlutterBinding.ensureInitialized();
  await SQLHelper.db();
  // runApp(const MyApp());

  // Modular Main Setting
  runApp(ModularApp(module: AppRoutesModular(), child: const MyApp()));

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
