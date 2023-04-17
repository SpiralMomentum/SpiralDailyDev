import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_memo_entity.freezed.dart';
part 'add_memo_entity.g.dart';

@freezed
class AddMemoEntity with _$AddMemoEntity {
  factory AddMemoEntity({
    String? title,
    String? author,
    String? content,
    String? madeDateTime,
    String? modifiedDateTime,
  }) = _AddMemoEntity;

  factory AddMemoEntity.fromJson(Map<String, dynamic> json) => _$AddMemoEntityFromJson(json);
}
