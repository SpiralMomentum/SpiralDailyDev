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

  const HomeState({
    this.status = HomeStatus.loading,
    this.index = 0,
  });

  HomeState copyWith({HomeStatus? status, int? index}) {
    return HomeState(
      status: status ?? this.status,
      index: index ?? this.index,
    );
  }

  @override
  List<Object?> get props => [
        status,
        index,
      ];
}
