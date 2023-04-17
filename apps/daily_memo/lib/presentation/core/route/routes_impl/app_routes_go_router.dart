import 'package:apps.daily_memo/data/repository_impl/memo_repository_impl.dart';
import 'package:apps.daily_memo/domain/model/home/memo_info.dart';
import 'package:apps.daily_memo/domain/model/home/memo_info_list.dart';
import 'package:apps.daily_memo/domain/repository_interface/memo/memo_repository.dart';
import 'package:apps.daily_memo/domain/usecase/memo/memo_usecase.dart';
import 'package:apps.daily_memo/presentation/core/route/app_routes.dart';
import 'package:apps.daily_memo/presentation/state/common_state.dart';
import 'package:apps.daily_memo/presentation/view/bottom_bar/bottom_bar.dart';
import 'package:apps.daily_memo/presentation/view/calendar/calendar_page.dart';
import 'package:apps.daily_memo/presentation/view/home/home_page.dart';
import 'package:apps.daily_memo/presentation/view/memo/memo_list_page.dart';
import 'package:apps.daily_memo/presentation/view/memo/memo_view.dart';
import 'package:apps.daily_memo/presentation/view_model/bottom_bar/bottom_bar_viewmodel.dart';
import 'package:apps.daily_memo/presentation/view_model/calendar/calendar_page_viewmodel.dart';
import 'package:apps.daily_memo/presentation/view_model/memo/memo_list_page_viewmodel.dart';
import 'package:apps.daily_memo/presentation/view_model/memo/memo_viewmodel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final Provider<MemoRepository> memoRepositoryProvider =
    Provider<MemoRepository>((ref) {
  return MemoRepositoryImpl();
});

final Provider<MemoUsecase> memoUsecaseProvider = Provider<MemoUsecase>((ref) {
  final MemoRepository memoRepository = ref.watch(memoRepositoryProvider);
  return MemoUsecase(memoRepository: memoRepository);
});

final memoViewModelProvider = StateNotifierProvider.autoDispose<MemoViewModel,
    CommonState<MemoInfoList?>>((ref) {
  return MemoViewModel(memoUsecase: ref.watch(memoUsecaseProvider));
});

final memoListPageViewModelProvider = StateNotifierProvider.autoDispose<
    MemoListPageViewModel, CommonState<MemoInfoList>>((ref) {
  // ref.watch(memoViewModelProvider);
  return MemoListPageViewModel(memoUsecase: ref.watch(memoUsecaseProvider));
});

final calendarPageViewModelProvider = StateNotifierProvider.autoDispose<
    CalendarPageViewModel, CommonState<Map<DateTime, List<MemoInfo>>>>((ref) {
  // ref.watch(memoViewModelProvider);
  return CalendarPageViewModel(ref.watch(memoUsecaseProvider));
});

final bottomBarViewModelProvider =
    StateNotifierProvider.autoDispose<BottomBarViewModel, CommonState<int>>(
        (ref) {
  final bottomNavigationItems = [
    BottomNavigationBarItem(label: 'home', icon: Icon(Icons.home)),
    BottomNavigationBarItem(
        label: 'calendar', icon: Icon(Icons.calendar_month)),
  ];
  return BottomBarViewModel(bottomNavigationItems);
});

extension AppRoutesGoRouter on AppRoutes {
  GoRoute get getRouter {
    switch (this) {
      case AppRoutes.HOME:
        return GoRoute(
          name: "home",
          path: AppRoutes.HOME.path,
          builder: (BuildContext context, GoRouterState state) {
            final BottomBar bottomBar = BottomBar();
            final MemoListPage memoListPage = MemoListPage();
            final CalendarPage calendarPage = CalendarPage();

            return ProviderScope(
              child: HomePage(
                bottomBar: bottomBar,
                memoListPage: memoListPage,
                calendarPage: calendarPage,
              ),
            );
          },
        );
      case AppRoutes.MEMO:
        return GoRoute(
          name: "memo",
          path: AppRoutes.MEMO.path,
          builder: (BuildContext context, GoRouterState state) {
            int? memoId;
            try {
              final result = state.extra as Map;
              memoId = result["memoId"];
            } catch (e) {
              memoId = null;
            }
            return MemoView(memoId);
          },
        );
      default:
        return GoRoute(
          name: "home",
          path: AppRoutes.HOME.path,
          builder: (BuildContext context, GoRouterState state) {
            final BottomBar bottomBar = BottomBar();
            final MemoListPage memoListPage = MemoListPage();
            final CalendarPage calendarPage = CalendarPage();

            return HomePage(
              bottomBar: bottomBar,
              memoListPage: memoListPage,
              calendarPage: calendarPage,
            );
          },
        );
    }
  }
}
