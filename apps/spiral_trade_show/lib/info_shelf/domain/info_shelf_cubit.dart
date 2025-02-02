import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spiral_trade_show/info_shelf/domain/info_shelf_state.dart';
import 'info_shelf_use_case.dart';

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
    response.fold(
        (failure) => emit(state.copyWith(
              status: InfoShelfStatus.failure,
            )),
        (infoList) => emit(state.copyWith(
              status: InfoShelfStatus.success,
              info: infoList,
            )));
  }

  Future<void> initialLoadInfoList() async {
    final response = await useCase.fetchInfoList(
      0,
      30,
    );
    response.fold(
        (failure) => emit(state.copyWith(
              status: InfoShelfStatus.failure,
            )),
        (infoList) => emit(state.copyWith(
              status: InfoShelfStatus.success,
              info: infoList,
            )));
  }
}
