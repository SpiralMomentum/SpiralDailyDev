import 'package:app_navigation/app_navigation.dart';
import 'package:apps.daily_memo/core/route/app_routes.dart';
import 'package:apps.daily_memo/data/repository_interface/memo/memo_repository.dart';
import 'package:apps.daily_memo/domain/bloc/home/home_bloc.dart';
import 'package:apps.daily_memo/domain/bloc/memo/memo_bloc.dart';
import 'package:apps.daily_memo/domain/bloc/memo/memo_event.dart';
import 'package:apps.daily_memo/presentation/view/home/home_page.dart';
import 'package:apps.daily_memo/presentation/view/memo/memo_list_page.dart';
import 'package:apps.daily_memo/presentation/view/memo/memo_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

final getIt = GetIt.instance;

extension AppRoutesGoRouter on AppRoutes {
  GoRoute get getRouter {
    switch (this) {
      case AppRoutes.home:
        return GoRoute(
          path: AppRoutes.home.path,
          builder: (BuildContext context, GoRouterState state) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<HomeBloc>(
                  create: (context) => HomeBloc(
                    routesController: getIt.get<RoutesController>(),
                  ),
                ),
                BlocProvider<MemoBloc>(
                  create: (_) => MemoBloc(
                    memoRepository: getIt.get<MemoRepository>(),
                    routesController: getIt.get<RoutesController>(),
                  )..add(GetAllMemos()),
                ),
              ],
              child: const HomeView(),
            );
          },
        );

      case AppRoutes.memo:
        return GoRoute(
          path: AppRoutes.memo.path,
          builder: (BuildContext context, GoRouterState state) {
            final Map? params = state.extra as Map?;

            return BlocProvider<MemoBloc>(
              create: (context) => MemoBloc(
                routesController: getIt.get<RoutesController>(),
                memoRepository: getIt.get<MemoRepository>(),
              ),
              child: MemoView(memoInfo: params?["memoInfo"]),
            );
          },
        );
      default:
        return GoRoute(
          path: AppRoutes.home.path,
          builder: (BuildContext context, GoRouterState state) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<HomeBloc>(
                  create: (context) => HomeBloc(
                    routesController: getIt.get<RoutesController>(),
                  ),
                ),
                BlocProvider<MemoBloc>(
                  create: (_) => MemoBloc(
                    memoRepository: getIt.get<MemoRepository>(),
                    routesController: getIt.get<RoutesController>(),
                  )..add(GetAllMemos()),
                ),
              ],
              child: const HomeView(),
            );
          },
        );
    }
  }
}
