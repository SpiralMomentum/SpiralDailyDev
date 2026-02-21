import 'package:app_navigation/app_navigation.dart';
import 'package:apps.daily_memo/core/analytics/analytics_events.dart';
import 'package:app_analytics/app_analytics.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/add_memo_use_case.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/delete_memo_use_case.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/get_all_memos_use_case.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/update_memo_use_case.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_event.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MemoBloc extends Bloc<MemoEvent, MemoState> {
  final GetAllMemosUseCase _getAllMemosUseCase;
  final AddMemoUseCase _addMemoUseCase;
  final UpdateMemoUseCase _updateMemoUseCase;
  final DeleteMemoUseCase _deleteMemoUseCase;
  final RoutesController _routesController;
  final AnalyticsTracker? _analyticsTracker;

  RoutesController get getRouteController => _routesController;

  MemoBloc({
    required GetAllMemosUseCase getAllMemosUseCase,
    required AddMemoUseCase addMemoUseCase,
    required UpdateMemoUseCase updateMemoUseCase,
    required DeleteMemoUseCase deleteMemoUseCase,
    required RoutesController routesController,
    AnalyticsTracker? analyticsTracker,
  })  : _getAllMemosUseCase = getAllMemosUseCase,
        _addMemoUseCase = addMemoUseCase,
        _updateMemoUseCase = updateMemoUseCase,
        _deleteMemoUseCase = deleteMemoUseCase,
        _routesController = routesController,
        _analyticsTracker = analyticsTracker,
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
    final result = await _getAllMemosUseCase();
    result.when(
      success: (memos) {
        emit(
          state.copyWith(
            memos: memos,
            status: MemoStatus.getAllMemosSuccess,
          ),
        );
      },
      error: (_) {
        emit(state.copyWith(status: MemoStatus.failure));
      },
    );
  }

  void _onAddMemo(
    AddMemo event,
    Emitter<MemoState> emit,
  ) async {
    emit(state.copyWith(status: MemoStatus.loading));
    final result = await _addMemoUseCase(
      title: event.title ?? " ",
      content: event.desc ?? "",
    );
    result.when(
      success: (saved) {
        if (saved) {
          _analyticsTracker?.trackEvent(AnalyticsEvents.memoCreated);
        }
        emit(
          state.copyWith(
            status: saved ? MemoStatus.addMemoSuccess : MemoStatus.failure,
          ),
        );
      },
      error: (_) => emit(state.copyWith(status: MemoStatus.failure)),
    );
  }

  void _onUpdateMemo(
    UpdateMemo event,
    Emitter<MemoState> emit,
  ) async {
    emit(state.copyWith(status: MemoStatus.loading));
    final result = await _updateMemoUseCase(
      memoId: event.memoId,
      title: event.title ?? " ",
      content: event.desc ?? "",
      madeDateTime: DateTime.now().toString(),
    );
    result.when(
      success: (saved) {
        if (saved) {
          _analyticsTracker?.trackEvent(
            AnalyticsEvents.memoUpdated,
            {'memo_id': event.memoId},
          );
        }
        emit(
          state.copyWith(
            status: saved ? MemoStatus.updateMemoSuccess : MemoStatus.failure,
          ),
        );
      },
      error: (_) => emit(state.copyWith(status: MemoStatus.failure)),
    );
  }

  void _onRemoveMemo(
    RemoveMemo event,
    Emitter<MemoState> emit,
  ) async {
    emit(state.copyWith(status: MemoStatus.loading));
    final result = await _deleteMemoUseCase(event.memoId);
    result.when(
      success: (saved) {
        if (saved) {
          _analyticsTracker?.trackEvent(
            AnalyticsEvents.memoDeleted,
            {'memo_id': event.memoId},
          );
        }
        emit(
          state.copyWith(
            status: saved ? MemoStatus.removeMemoSuccess : MemoStatus.failure,
          ),
        );
      },
      error: (_) => emit(state.copyWith(status: MemoStatus.failure)),
    );
  }

  void _backToHome(
    BackToHome event,
    Emitter<MemoState> emit,
  ) {
    _routesController.pop(event.context);
  }
}
