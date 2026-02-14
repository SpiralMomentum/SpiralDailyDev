import 'package:app_navigation/app_navigation.dart';
import 'package:apps.daily_memo/app/route/app_routes.dart';
import 'package:apps.daily_memo/core/analytics/analytics_events.dart';
import 'package:apps.daily_memo/core/analytics/analytics_tracker.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/home/home_event.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/home/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final RoutesController routesController;
  final AnalyticsTracker? _analyticsTracker;

  HomeBloc({
    required this.routesController,
    AnalyticsTracker? analyticsTracker,
  })  : _analyticsTracker = analyticsTracker,
        super(
          const HomeState(),
        ) {
    on<MoveTab>(_onMoveTab);
    on<MoveToAddMemo>(_onMoveToAddMemo);
  }

  void _onMoveTab(
    MoveTab event,
    Emitter<HomeState> emit,
  ) async {
    // 탭 인덱스에 따라 적절한 이벤트를 트래킹한다
    final eventName = switch (event.tabIndex) {
      0 => AnalyticsEvents.memoListTabSelected,
      1 => AnalyticsEvents.calendarTabSelected,
      _ => null,
    };
    if (eventName != null) {
      _analyticsTracker?.trackEvent(eventName);
    }

    emit(state.copyWith(status: HomeStatus.success, index: event.tabIndex));
  }

  void _onMoveToAddMemo(
    MoveToAddMemo event,
    Emitter<HomeState> emit,
  ) async {
    routesController.push(
      event.context,
      AppRoutes.memo.path,
      extra: {
        "bloc": event.memoBloc,
      },
    );
    emit(state.copyWith(status: HomeStatus.success));
  }
}
