import 'package:app_navigation/app_navigation.dart';
import 'package:apps.daily_memo/app/route/app_routes.dart';
import 'package:app_analytics/app_analytics.dart';
import 'package:apps.daily_memo/features/memo/domain/repositories/memo_repository.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/add_memo_use_case.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/delete_memo_use_case.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/get_all_memos_use_case.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/update_memo_use_case.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/home/home_bloc.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_bloc.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_event.dart';
import 'package:apps.daily_memo/features/memo/presentation/views/home_page.dart';
import 'package:apps.daily_memo/features/memo/presentation/views/memo_view.dart';
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
            final repository = getIt.get<MemoRepository>();
            final analyticsTracker = getIt.get<AnalyticsTracker>();
            return MultiBlocProvider(
              providers: [
                BlocProvider<HomeBloc>(
                  create: (context) => HomeBloc(
                    routesController: getIt.get<RoutesController>(),
                    analyticsTracker: analyticsTracker,
                  ),
                ),
                BlocProvider<MemoBloc>(
                  create: (_) => MemoBloc(
                    getAllMemosUseCase:
                        GetAllMemosUseCase(repository: repository),
                    addMemoUseCase: AddMemoUseCase(repository: repository),
                    updateMemoUseCase: UpdateMemoUseCase(repository: repository),
                    deleteMemoUseCase: DeleteMemoUseCase(repository: repository),
                    routesController: getIt.get<RoutesController>(),
                    analyticsTracker: analyticsTracker,
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
            final repository = getIt.get<MemoRepository>();

            return BlocProvider<MemoBloc>(
              create: (context) => MemoBloc(
                routesController: getIt.get<RoutesController>(),
                getAllMemosUseCase:
                    GetAllMemosUseCase(repository: repository),
                addMemoUseCase: AddMemoUseCase(repository: repository),
                updateMemoUseCase: UpdateMemoUseCase(repository: repository),
                deleteMemoUseCase: DeleteMemoUseCase(repository: repository),
              ),
              child: MemoView(memoInfo: params?["memoInfo"]),
            );
          },
        );
      default:
        return GoRoute(
          path: AppRoutes.home.path,
          builder: (BuildContext context, GoRouterState state) {
            final repository = getIt.get<MemoRepository>();
            return MultiBlocProvider(
              providers: [
                BlocProvider<HomeBloc>(
                  create: (context) => HomeBloc(
                    routesController: getIt.get<RoutesController>(),
                  ),
                ),
                BlocProvider<MemoBloc>(
                  create: (_) => MemoBloc(
                    getAllMemosUseCase:
                        GetAllMemosUseCase(repository: repository),
                    addMemoUseCase: AddMemoUseCase(repository: repository),
                    updateMemoUseCase: UpdateMemoUseCase(repository: repository),
                    deleteMemoUseCase: DeleteMemoUseCase(repository: repository),
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
