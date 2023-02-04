import 'package:apps.daily_memo/presentation/core/route/app_routes.dart';
import 'package:apps.daily_memo/presentation/view/home/home_page.dart';
import 'package:apps.daily_memo/presentation/view/login/login_page.dart';
import 'package:apps.daily_memo/presentation/view/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension AppRoutesGoRouter on AppRoutes {
  GoRoute get getRouter{
    switch(this){
      case AppRoutes.HOME:
        return  GoRoute(
          path: AppRoutes.HOME.path,
          builder: (BuildContext context, GoRouterState state) {
            return const HomePage();
          },
        );
      case AppRoutes.SPLASH:
        return GoRoute(
          path: AppRoutes.SPLASH.path,
          builder: (BuildContext context, GoRouterState state) =>
          const SplashPage(),
        );
      case AppRoutes.LOGIN:
        return  GoRoute(
          path: AppRoutes.LOGIN.path,
          builder: (BuildContext context, GoRouterState state) =>
          const LoginPage(),
        );
      default:
        return  GoRoute(
          path: AppRoutes.HOME.path,
          builder: (BuildContext context, GoRouterState state) {
            return const HomePage();
          },
        );
    }
  }
}
