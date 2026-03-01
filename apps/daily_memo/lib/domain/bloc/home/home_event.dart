import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {}
// vs sealed class & const

final class MoveTab extends HomeEvent {
  final int tabIndex;

  MoveTab(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

final class MoveToAddMemo extends HomeEvent {
  MoveToAddMemo();

  @override
  List<Object?> get props => [];
}
