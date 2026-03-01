import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {}

final class MoveTab extends HomeEvent {
  final int tabIndex;

  MoveTab(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}
