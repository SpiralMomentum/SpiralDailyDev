import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:equatable/equatable.dart';

enum MemoStatus {
  initial,
  loading,
  getAllMemosSuccess,
  addMemoSuccess,
  updateMemoSuccess,
  removeMemoSuccess,
  failure,
}

class MemoState extends Equatable {
  final MemoStatus status;
  final List<MemoInfoEntity> memos;
  final int memoId;
  final String title;
  final String desc;
  final bool isComplete;

  const MemoState({
    this.status = MemoStatus.loading,
    this.memos = const [],
    this.memoId = -1,
    this.title = "",
    this.desc = "",
    this.isComplete = false,
  });

  MemoState copyWith({
    MemoStatus? status,
    List<MemoInfoEntity>? memos,
    int? memoId,
    String? title,
    String? desc,
    bool? isComplete,
  }) {
    return MemoState(
      status: status ?? this.status,
      memoId: memoId ?? this.memoId,
      memos: memos ?? this.memos,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  List<Object?> get props => [
        status,
        memos,
        memoId,
        title,
        desc,
        isComplete,
      ];
}
