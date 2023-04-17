import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_memo_entity.freezed.dart';
part 'saved_memo_entity.g.dart';

@freezed
class SavedMemoEntity with _$SavedMemoEntity {
  factory SavedMemoEntity({
    required int memoId,
    String? title,
    String? author,
    String? content,
    String? madeDateTime,
    String? modifiedDateTime,
  }) = _SavedMemoEntity;

  factory SavedMemoEntity.fromJson(Map<String, dynamic> json) => _$SavedMemoEntityFromJson(json);

}
