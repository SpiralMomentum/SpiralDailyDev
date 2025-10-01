import 'package:app_navigation/app_navigation.dart';
import 'package:apps.daily_memo/data/repository_interface/memo/memo_repository.dart';
import 'package:apps.daily_memo/domain/bloc/memo/memo_event.dart';
import 'package:apps.daily_memo/domain/bloc/memo/memo_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MemoBloc extends Bloc<MemoEvent, MemoState> {
  final MemoRepository _memoRepository;
  final RoutesController _routesController;

  RoutesController get getRouteController => _routesController;

  MemoBloc({
    required MemoRepository memoRepository,
    required RoutesController routesController,
  })  : _memoRepository = memoRepository,
        _routesController = routesController,
        super(
          const MemoState(),
        ) {
    on<GetAllMemos>(_onGetAllMemos);
    on<AddMemo>(_onAddMemo);
    on<UpdateMemo>(_onUpdateMemo);
    on<RemoveMemo>(_onRemoveMemo);
    on<BackToHome>(_backToHome);
  }

  void _onGetAllMemos(
    GetAllMemos event,
    Emitter<MemoState> emit,
  ) async {
    emit(state.copyWith(status: MemoStatus.loading));
    try {
      final result = await _memoRepository.getAllMemoInfo;

      emit(
          state.copyWith(memos: result, status: MemoStatus.getAllMemosSuccess));
    } catch (e) {
      emit(state.copyWith(status: MemoStatus.failure));
    }
  }

  void _onAddMemo(
    AddMemo event,
    Emitter<MemoState> emit,
  ) async {
    emit(state.copyWith(status: MemoStatus.loading));
    try {
      final bool result = await _memoRepository.addMemo(
        title: event.title ?? " ",
        content: event.desc ?? "",
      );
      if (result == false) {
        emit(state.copyWith(status: MemoStatus.failure));
      } else {
        emit(state.copyWith(status: MemoStatus.addMemoSuccess));
      }
    } catch (e) {
      emit(state.copyWith(status: MemoStatus.failure));
    }
  }

  void _onUpdateMemo(
    UpdateMemo event,
    Emitter<MemoState> emit,
  ) async {
    emit(state.copyWith(status: MemoStatus.loading));
    try {
      final bool result = await _memoRepository.modifyMemo(
        memoId: event.memoId,
        title: event.title ?? " ",
        content: event.desc ?? "",
        madeDateTime: DateTime.now().toString(),
      );
      if (result == false) {
        emit(state.copyWith(status: MemoStatus.failure));
      } else {
        emit(state.copyWith(status: MemoStatus.updateMemoSuccess));
      }
    } catch (e) {
      emit(state.copyWith(status: MemoStatus.failure));
    }
  }

  void _onRemoveMemo(
    RemoveMemo event,
    Emitter<MemoState> emit,
  ) async {
    emit(state.copyWith(status: MemoStatus.loading));
    try {
      final bool result = await _memoRepository.deleteMemo(event.memoId);
      if (result == false) {
        emit(state.copyWith(status: MemoStatus.failure));
      } else {
        emit(state.copyWith(status: MemoStatus.removeMemoSuccess));
      }
    } catch (e) {
      emit(state.copyWith(status: MemoStatus.failure));
    }
  }

  void _backToHome(
    BackToHome event,
    Emitter<MemoState> emit,
  ) {
    _routesController.pop(event.context);
  }
}
