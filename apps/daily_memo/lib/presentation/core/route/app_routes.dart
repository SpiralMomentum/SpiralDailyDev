import 'package:apps.daily_memo/presentation/view/home/home_page.dart';
import 'package:apps.daily_memo/presentation/view/login/login_page.dart';
import 'package:apps.daily_memo/presentation/view/splash/splash_page.dart';
import 'package:flutter/cupertino.dart';

enum AppRoutes {
  HOME,
  MEMO,
}

extension AppRoutesPath on AppRoutes {
  String get path {
    switch (this) {
      case AppRoutes.HOME:
        return '/';
      case AppRoutes.MEMO:
        return '/memo';
      default:
        return '/';
    }
  }
}


