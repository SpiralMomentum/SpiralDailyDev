import 'package:apps.daily_memo/domain/model/home/memo_info.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'memo_info_list.freezed.dart';

@freezed
class MemoInfoList with _$MemoInfoList {
  const factory MemoInfoList({required List<MemoInfo> values}) = _MemoInfoList;

  const MemoInfoList._();

  operator [](final int index) => values[index];

  int get length => values.length;

  MemoInfoList addTodo(final MemoInfo memoInfo) => copyWith(values: [...values, memoInfo]);

  MemoInfoList updateTodo(final MemoInfo newMemoInfo) {
    return copyWith(values: values.map((memoInfo) => memoInfo.uniqueId == newMemoInfo.uniqueId ? newMemoInfo : memoInfo).toList());
  }

  MemoInfoList removeTodoById(final MemoInfo id) => copyWith(values: values.where((memoInfo) => memoInfo.uniqueId != id).toList());
}
