import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spiral_trade_show/features/info_shelf/domain/info_shelf_use_case.dart';

import 'info_shelf_state.dart';

class InfoShelfCubit extends Cubit<InfoShelfState> {
  final InfoShelfUseCase useCase;

  InfoShelfCubit(super.initialState, this.useCase);

  Future<void> fetchInfoList(
    int startIndex,
    int endIndex,
  ) async {
    final response = await useCase.fetchInfoList(
      startIndex,
      endIndex,
    );
    response.when(
      success: (infoList) => emit(
        state.copyWith(
          status: InfoShelfStatus.success,
          info: infoList,
        ),
      ),
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
      success: (infoList) => emit(
        state.copyWith(
          status: InfoShelfStatus.success,
          info: infoList,
        ),
      ),
      error: (_) => emit(
        state.copyWith(
          status: InfoShelfStatus.failure,
        ),
      ),
    );
  }
}
