import 'package:apps.daily_memo/data/repository_interface/memo/memo_repository.dart';
import 'package:apps.daily_memo/domain/entity/memo/memo_info_entity.dart';
import 'package:apps.daily_memo/domain/bloc/memo/memo_event.dart';
import 'package:apps.daily_memo/domain/bloc/memo/memo_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MemoBloc extends Bloc<MemoEvent, MemoState> {
  final MemoRepository _memoRepository;

  MemoBloc(this._memoRepository)
      : super(
          const MemoState(),
        ) {
    on<GetAllMemos>(_onGetAllMemos);
    on<GetMemo>(_onGetMemo);
    on<AddMemo>(_onAddMemo);
    on<UpdateMemo>(_onUpdateMemo);
    on<RemoveMemo>(_onRemoveMemo);
  }

  void _onGetAllMemos(
    GetAllMemos event,
    Emitter<MemoState> emit,
  ) async {
    emit(state.copyWith(status: MemoStatus.loading));
    try {
      final result = await _memoRepository.getAllMemoInfo;

      emit(state.copyWith(memos: result, status: MemoStatus.getAllMemosSuccess));
    } catch (e) {
      emit(state.copyWith(status: MemoStatus.failure));
    }
  }

  void _onGetMemo(
    GetMemo event,
    Emitter<MemoState> emit,
  ) async {
    emit(state.copyWith(status: MemoStatus.loading));
    try {
      final MemoInfoEntity? result =
          await _memoRepository.getMemoInfoById(event.memoId);

      if (result == null) {
        emit(state.copyWith(status: MemoStatus.failure));
      } else {
        emit(state.copyWith(memos: [result], status: MemoStatus.getMemoSuccess));
      }
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
        emit(state.copyWith(status: MemoStatus.changeMemoSuccess));
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
        emit(state.copyWith(status: MemoStatus.changeMemoSuccess));
      }
    } catch (e) {
      emit(state.copyWith(status: MemoStatus.failure));
    }
  }
}
