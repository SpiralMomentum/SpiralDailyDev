import 'package:apps.daily_memo/presentation/view/home/home_page.dart';
import 'package:apps.daily_memo/presentation/view/login/login_page.dart';
import 'package:apps.daily_memo/presentation/view/splash/splash_page.dart';
import 'package:flutter/cupertino.dart';

enum AppRoutes {
  HOME,
  SPLASH,
  LOGIN,
}

extension AppRoutesPath on AppRoutes {
  String get path {
    switch (this) {
      case AppRoutes.HOME:
        return '/';
      case AppRoutes.SPLASH:
        return '/splash';
      case AppRoutes.LOGIN:
        return '/login';
      default:
        return '/';
    }
  }
}


