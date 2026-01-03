import 'package:exchange_rate_calculator/app/route/app_routes.dart';
import 'package:exchange_rate_calculator/features/exchange/data/datasources/exchange_adapter_api_client.dart';
import 'package:exchange_rate_calculator/features/exchange/data/repositories/exchange_repository_impl.dart';
import 'package:exchange_rate_calculator/features/exchange/domain/usecases/get_exchange_info_use_case.dart';
import 'package:exchange_rate_calculator/features/exchange/domain/usecases/load_exchange_info_use_case.dart';
import 'package:exchange_rate_calculator/features/exchange/external/remote/exchange_remote_data_source_impl.dart';
import 'package:exchange_rate_calculator/features/exchange/presentation/view_models/home_view_model.dart';
import 'package:exchange_rate_calculator/features/exchange/presentation/views/home_view.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension AppRoutesGoRouter on AppRoutes {
  GoRoute get getRouter {
    switch (this) {
      case AppRoutes.HOME:
        return GoRoute(
          path: AppRoutes.HOME.path,
          builder: (BuildContext context, GoRouterState state) {
            final remoteDataSource = ExchangeRemoteDataSourceImpl();
            final adapter = ExchangeAdapterApiClient(
              remoteDataSource: remoteDataSource,
            );
            final repository = ExchangeRepositoryImpl(adapter: adapter);
            return HomeView(
              viewModel: HomeViewModel(
                getExchangeInfoUseCase:
                    GetExchangeInfoUseCase(repository: repository),
                loadExchangeInfoUseCase:
                    LoadExchangeInfoUseCase(repository: repository),
              ),
            );
          },
        );
      default:
        return GoRoute(
          path: AppRoutes.HOME.path,
          builder: (BuildContext context, GoRouterState state) {
            return const SizedBox.shrink();
          },
        );
    }
  }
}
