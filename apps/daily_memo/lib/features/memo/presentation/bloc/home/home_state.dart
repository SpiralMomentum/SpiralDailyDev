import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_bloc.dart';
import 'package:equatable/equatable.dart';

enum HomeStatus {
  initial,
  loading,
  success,
  failure,
}

final class HomeState extends Equatable {
  final HomeStatus status;
  final int index;
  final MemoBloc? memoBloc;

  const HomeState({
    this.status = HomeStatus.loading,
    this.index = 0,
    this.memoBloc,
  });

  HomeState copyWith({
    HomeStatus? status,
    int? index,
    MemoBloc? memoBloc,
  }) {
    return HomeState(
      status: status ?? this.status,
      index: index ?? this.index,
      memoBloc: memoBloc ?? this.memoBloc,
    );
  }

  @override
  List<Object?> get props => [
        status,
        index,
        memoBloc,
      ];
}
