import 'package:apps.daily_memo/core/analytics/analytics_events.dart';
import 'package:app_analytics/app_analytics.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/home/home_event.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/home/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final AnalyticsTracker? _analyticsTracker;

  HomeBloc({
    AnalyticsTracker? analyticsTracker,
  })  : _analyticsTracker = analyticsTracker,
        super(
          const HomeState(),
        ) {
    on<MoveTab>(_onMoveTab);
  }

  Future<void> _onMoveTab(
    MoveTab event,
    Emitter<HomeState> emit,
  ) async {
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
}
