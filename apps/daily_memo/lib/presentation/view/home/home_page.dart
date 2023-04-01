import 'package:apps.daily_memo/presentation/core/route/app_routes.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_controller.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_controller_impl/routes_controller_go_router_impl.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_impl/app_routes_go_router.dart';
import 'package:apps.daily_memo/presentation/view/bottom_bar/bottom_bar.dart';
import 'package:apps.daily_memo/presentation/view/calendar/calendar_page.dart';
import 'package:apps.daily_memo/presentation/view/home/home_app_bar.dart';
import 'package:apps.daily_memo/presentation/view/memo/memo_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends StatelessWidget {
  final BottomBar bottomBar;
  final RoutesController _routesController = RoutesControllerGoRouterImpl();

  final MemoListPage memoListPage;
  final CalendarPage calendarPage;

  HomePage({
    super.key,
    required this.bottomBar,
    required this.memoListPage,
    required this.calendarPage,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: homeAppBar(context),
        ),
        body: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            final state = ref.watch(bottomBarViewModelProvider);

            return state.maybeWhen(
              success: (content) => getCurrentPage(content),
              init: (content) => getCurrentPage(content),
              orElse: () => const SizedBox.shrink(),
            );
          },
        ),
        bottomNavigationBar: bottomBar,
      ),
    );
  }

  Widget homeAppBar(BuildContext context){
    return HomeAppBar(
      homeAppBarItems: [
        HomeAppBarItem(
          leadingText: "추가",
          onTap: () =>
              _routesController.toPushNamed(context, AppRoutes.MEMO.path),
        )
      ],
    );
  }

  Widget getCurrentPage(int index){
    return index == 0 ? memoListPage : calendarPage;
  }
}
