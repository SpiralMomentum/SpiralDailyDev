import 'package:apps.daily_memo/data/repository_impl/memo_repository_impl.dart';
import 'package:apps.daily_memo/presentation/core/route/app_routes.dart';
import 'package:apps.daily_memo/presentation/view/bottom_bar/bottom_bar.dart';
import 'package:apps.daily_memo/presentation/view/home/home_page.dart';
import 'package:apps.daily_memo/presentation/view/login/login_page.dart';
import 'package:apps.daily_memo/presentation/view/splash/splash_page.dart';
import 'package:apps.daily_memo/presentation/view_model/home/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension AppRoutesGoRouter on AppRoutes {
  GoRoute get getRouter {
    switch (this) {
      case AppRoutes.HOME:
        return GoRoute(
          path: AppRoutes.HOME.path,
          builder: (BuildContext context, GoRouterState state) {
            final HomeViewModel homeViewModel = HomeViewModel(
                memoRepository: MemoRepositoryImpl());
            final BottomBar bottomBar = BottomBar(navigationItems: const [
              BottomNavigationBarItem(label: 'home', icon: Icon(Icons.home)),
              BottomNavigationBarItem(
                  label: 'calendar', icon: Icon(Icons.calendar_month)),
            ]);
            return HomePage(
              homeViewModel: homeViewModel,
              bottomBar: bottomBar,
            );
          },
        );
      case AppRoutes.SPLASH:
        return GoRoute(
          path: AppRoutes.SPLASH.path,
          builder: (BuildContext context, GoRouterState state) =>
              const SplashPage(),
        );
      case AppRoutes.LOGIN:
        return GoRoute(
          path: AppRoutes.LOGIN.path,
          builder: (BuildContext context, GoRouterState state) =>
              const LoginPage(),
        );
      default:
        return GoRoute(
          path: AppRoutes.HOME.path,
          builder: (BuildContext context, GoRouterState state) {
            final HomeViewModel homeViewModel = HomeViewModel(
                memoRepository: MemoRepositoryImpl());
            final BottomBar bottomBar = BottomBar(navigationItems: const [
              BottomNavigationBarItem(label: 'home', icon: Icon(Icons.home)),
              BottomNavigationBarItem(
                  label: 'calendar', icon: Icon(Icons.calendar_month)),
            ]);
            return HomePage(
              homeViewModel: homeViewModel,
              bottomBar: bottomBar,
            );
          },
        );
    }
  }
}
