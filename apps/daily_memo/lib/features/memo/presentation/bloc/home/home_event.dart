import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class HomeEvent extends Equatable {}
// vs sealed class & const

final class MoveTab extends HomeEvent {
  final int tabIndex;

  MoveTab(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

final class MoveToAddMemo extends HomeEvent {
  final MemoBloc memoBloc;
  final BuildContext context;

  MoveToAddMemo({required this.memoBloc, required this.context});

  @override
  List<Object?> get props => [];
}
