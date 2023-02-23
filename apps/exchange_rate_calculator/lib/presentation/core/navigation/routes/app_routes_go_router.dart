import 'package:exchange_rate_calculator/presentation/core/navigation/routes/app_routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

extension AppRoutesGoRouter on AppRoutes {
  GoRoute get getRouter {
    switch (this) {
      case AppRoutes.HOME:
        return GoRoute(
          path: AppRoutes.HOME.path,
          builder: (BuildContext context, GoRouterState state) {
            // return HomePage(
            //   homeViewModel:
            //       HomeViewModel(memoRepository: MemoRepositoryImpl()),
            // );
            return Container();
          },
        );
      default:
        return GoRoute(
          path: AppRoutes.HOME.path,
          builder: (BuildContext context, GoRouterState state) {
            return Container();
          },
        );
    }
  }
}
