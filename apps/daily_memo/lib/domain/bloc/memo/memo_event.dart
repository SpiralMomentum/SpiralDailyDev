import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

sealed class MemoEvent extends Equatable {}

final class GetAllMemos extends MemoEvent {
  @override
  List<Object?> get props => [];
}

// final class GetMemo extends MemoEvent {
//   final int memoId;
//
//   GetMemo(this.memoId);
//
//   @override
//   List<Object?> get props => [];
// }

final class AddMemo extends MemoEvent {
  final String? title;
  final String? desc;

  AddMemo(this.title, this.desc);

  @override
  List<Object?> get props => [];
}

final class UpdateMemo extends MemoEvent {
  final int memoId;
  final String? title;
  final String? desc;

  UpdateMemo(this.memoId, this.title, this.desc);

  @override
  List<Object?> get props => [];
}

final class RemoveMemo extends MemoEvent {
  final int memoId;

  RemoveMemo(this.memoId);

  @override
  List<Object?> get props => [];
}

final class BackToHome extends MemoEvent {
  final BuildContext context;

  BackToHome(this.context);

  @override
  List<Object?> get props => [];
}
