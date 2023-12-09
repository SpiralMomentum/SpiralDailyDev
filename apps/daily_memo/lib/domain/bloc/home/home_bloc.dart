import 'package:apps.daily_memo/core/route/routes_controller.dart';
import 'package:apps.daily_memo/core/route/routes_controller_impl/routes_controller_go_router_impl.dart';
import 'package:apps.daily_memo/domain/bloc/home/home_event.dart';
import 'package:apps.daily_memo/domain/bloc/home/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final RoutesController routesController = RoutesControllerGoRouterImpl();

  HomeBloc()
      : super(
          const HomeState(),
        ) {
    on<MoveTab>(_onMoveTab);
  }

  void _onMoveTab(
    MoveTab event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.success, index: event.tabIndex));
  }

}
