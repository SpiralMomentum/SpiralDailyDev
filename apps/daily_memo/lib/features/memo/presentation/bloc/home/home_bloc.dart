import 'package:app_navigation/app_navigation.dart';
import 'package:apps.daily_memo/app/route/app_routes.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/home/home_event.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/home/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final RoutesController routesController;

  HomeBloc({required this.routesController})
      : super(
          const HomeState(),
        ) {
    on<MoveTab>(_onMoveTab);
    on<MoveToAddMemo>(_onMoveToAddMemo);
  }

  void _onMoveTab(
    MoveTab event,
    Emitter<HomeState> emit,
  ) async {
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
