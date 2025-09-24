import 'package:core_app_shell/core_app_shell.dart';
import 'package:exchange_rate_calculator/presentation/core/navigation/routes/app_routes.dart';
import 'package:exchange_rate_calculator/presentation/core/navigation/routes/app_routes_go_router.dart';
import 'package:exchange_rate_calculator/presentation/view/home/home_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('renders home view as the initial route', (tester) async {
    final router = GoRouter(
      routes: AppRoutes.values.map((e) => e.getRouter).toList(),
    );

    await tester.pumpWidget(SpiralRouterApp(router: router));
    await tester.pumpAndSettle();

    expect(find.byType(HomeView), findsOneWidget);
  });
}
