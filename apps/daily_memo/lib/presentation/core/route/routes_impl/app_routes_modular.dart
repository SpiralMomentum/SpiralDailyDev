import 'package:apps.daily_memo/data/repository_impl/MemoRepositoryImpl.dart';
import 'package:apps.daily_memo/presentation/core/route/app_routes.dart';
import 'package:apps.daily_memo/presentation/view/home/home_page.dart';
import 'package:apps.daily_memo/presentation/view/login/login_page.dart';
import 'package:apps.daily_memo/presentation/view/splash/splash_page.dart';
import 'package:apps.daily_memo/presentation/view_model/home/home_viewmodel.dart';
import 'package:flutter_modular/flutter_modular.dart';

extension AppRoutesModularExtension on AppRoutes {
  ChildRoute get getRouter {
    switch (this) {
      case AppRoutes.HOME:
        return ChildRoute(
          AppRoutes.HOME.path,
          child: (context, args) {
            return HomePage(
              homeViewModel:
              HomeViewModel(memoRepository: MemoRepositoryImpl()),
            );
          },
        );
      case AppRoutes.SPLASH:
        return ChildRoute(
          AppRoutes.SPLASH.path,
          child: (context, args) => const SplashPage(),
        );
      case AppRoutes.LOGIN:
        return ChildRoute(
          AppRoutes.LOGIN.path,
          child: (context, args) => const LoginPage(),
        );
      default:
        return ChildRoute(
          AppRoutes.HOME.path,
          child: (context, args) {
            return HomePage(
              homeViewModel:
                  HomeViewModel(memoRepository: MemoRepositoryImpl()),
            );
          },
        );
    }
  }
}

class AppRoutesModular extends Module {
  @override
  List<Bind<Object>> get binds => super.binds;

  @override
  List<ModularRoute> get routes =>
      AppRoutes.values.map((e) => e.getRouter).toList();
}
