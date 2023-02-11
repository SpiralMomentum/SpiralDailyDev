import 'package:apps.daily_memo/data/repository_impl/memo_repository_impl.dart';
import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';
import 'package:apps.daily_memo/domain/usecase/memo_usecase.dart';
import 'package:apps.daily_memo/presentation/core/route/app_routes.dart';
import 'package:apps.daily_memo/presentation/view/home/home_page.dart';
import 'package:apps.daily_memo/presentation/view/login/login_page.dart';
import 'package:apps.daily_memo/presentation/view/memo/memo_view.dart';
import 'package:apps.daily_memo/presentation/view/splash/splash_page.dart';
import 'package:apps.daily_memo/presentation/view_model/home/home_viewmodel.dart';
import 'package:apps.daily_memo/presentation/view_model/memo/memo_viewmodel.dart';
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
      case AppRoutes.MEMO:
        return ChildRoute(
          AppRoutes.MEMO.path,
          child: (context, args) {
            int? memoId;
            try{
              memoId = args.data["memoId"];
            }catch(e){
              memoId = null;
            }
            return MemoView(
              memoViewModel: MemoViewModel(
                memoId: memoId,
                memoRepository: MemoRepositoryImpl(),
              ),
            );
          },
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
