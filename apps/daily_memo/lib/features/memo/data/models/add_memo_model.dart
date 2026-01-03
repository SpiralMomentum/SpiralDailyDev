import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_memo_model.freezed.dart';
part 'add_memo_model.g.dart';

@freezed
class AddMemoModel with _$AddMemoModel {
  factory AddMemoModel({
    final String? title,
    final String? author,
    final String? content,
    final String? madeDateTime,
    final String? modifiedDateTime,
  }) = _AddMemoModel;

  factory AddMemoModel.fromJson(Map<String, dynamic> json) => _$AddMemoModelFromJson(json);
}
