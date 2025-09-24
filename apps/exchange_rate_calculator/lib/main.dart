import 'package:core_app_shell/core_app_shell.dart';
import 'package:exchange_rate_calculator/data/repository_impl/exchange/exchange_repository_impl.dart';
import 'package:exchange_rate_calculator/presentation/core/navigation/routes/app_routes.dart';
import 'package:exchange_rate_calculator/presentation/core/navigation/routes/app_routes_go_router.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  await runSpiralRouterApp(
    bootstrap: () async {
      await ExchangeRepositoryImpl().loadAllExchangeInfo();
    },
    router: GoRouter(
      routes: AppRoutes.values.map((e) => e.getRouter).toList(),
    ),
  );
}
