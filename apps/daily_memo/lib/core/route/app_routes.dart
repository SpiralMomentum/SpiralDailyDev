import 'package:apps.daily_memo/presentation/view/home/home_page.dart';
import 'package:apps.daily_memo/presentation/view/memo/memo_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

enum AppRoutes {
  home,
  memo,
}

extension AppRoutesPath on AppRoutes {
  String get path {
    switch (this) {
      case AppRoutes.home:
        return '/';
      case AppRoutes.memo:
        return '/memo';
      default:
        return '/';
    }
  }
}
