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

extension AppRoutesGoRouter on AppRoutes {
  GoRoute get getRouter {
    switch (this) {
      case AppRoutes.home:
        return GoRoute(
          path: AppRoutes.home.path,
          builder: (BuildContext context, GoRouterState state) {
            return const HomePage();
          },
        );
      case AppRoutes.memo:
        return GoRoute(
          path: AppRoutes.memo.path,
          builder: (BuildContext context, GoRouterState state) {
            final Map? params = state.extra as Map?;
            return MemoPage(params?["memoId"]);
          },
        );
      default:
        return GoRoute(
          path: AppRoutes.home.path,
          builder: (BuildContext context, GoRouterState state) {
            // const CalendarPage calendarPage = CalendarPage();

            return const HomePage();
          },
        );
    }
  }
}
