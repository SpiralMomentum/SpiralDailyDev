import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spiral_trade_show/core/analytics/analytics_events.dart';
import 'package:spiral_trade_show/core/analytics/analytics_tracker.dart';
import 'package:spiral_trade_show/features/info_shelf/domain/info_shelf_use_case.dart';

import 'info_shelf_state.dart';

class InfoShelfCubit extends Cubit<InfoShelfState> {
  final InfoShelfUseCase useCase;
  final AnalyticsTracker? _analyticsTracker;

  InfoShelfCubit(
    super.initialState,
    this.useCase, {
    AnalyticsTracker? analyticsTracker,
  }) : _analyticsTracker = analyticsTracker;

  Future<void> fetchInfoList(
    int startIndex,
    int endIndex,
  ) async {
    final response = await useCase.fetchInfoList(
      startIndex,
      endIndex,
    );
    response.when(
      success: (infoList) {
        emit(
          state.copyWith(
            status: InfoShelfStatus.success,
            info: infoList,
          ),
        );
        _analyticsTracker?.trackEvent(
          AnalyticsEvents.exhibitionListViewed,
          {'count': infoList.length},
        );
      },
      error: (_) => emit(
        state.copyWith(
          status: InfoShelfStatus.failure,
        ),
      ),
    );
  }

  Future<void> initialLoadInfoList() async {
    final response = await useCase.fetchInfoList(
      0,
      30,
    );
    response.when(
      success: (infoList) {
        emit(
          state.copyWith(
            status: InfoShelfStatus.success,
            info: infoList,
          ),
        );
        _analyticsTracker?.trackEvent(
          AnalyticsEvents.exhibitionListViewed,
          {'count': infoList.length},
        );
      },
      error: (_) => emit(
        state.copyWith(
          status: InfoShelfStatus.failure,
        ),
      ),
    );
  }
}
