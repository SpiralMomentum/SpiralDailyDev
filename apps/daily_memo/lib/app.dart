import 'package:apps.daily_memo/core/route/app_routes.dart';
import 'package:go_router/go_router.dart';

GoRouter createDailyMemoRouter() {
  return GoRouter(
    routes: AppRoutes.values.map((e) => e.getRouter).toList(),
  );
}
