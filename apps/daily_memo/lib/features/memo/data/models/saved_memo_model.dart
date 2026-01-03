import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_memo_model.freezed.dart';
part 'saved_memo_model.g.dart';

@freezed
class SavedMemoModel with _$SavedMemoModel {
  factory SavedMemoModel({
    required int memoId,
    String? title,
    String? author,
    String? content,
    String? madeDateTime,
    String? modifiedDateTime,
  }) = _SavedMemoModel;

  factory SavedMemoModel.fromJson(Map<String, dynamic> json) => _$SavedMemoModelFromJson(json);

}
