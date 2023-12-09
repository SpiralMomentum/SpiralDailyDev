// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_memo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_SavedMemoModel _$$_SavedMemoModelFromJson(Map<String, dynamic> json) =>
    _$_SavedMemoModel(
      memoId: json['memoId'] as int,
      title: json['title'] as String?,
      author: json['author'] as String?,
      content: json['content'] as String?,
      madeDateTime: json['madeDateTime'] as String?,
      modifiedDateTime: json['modifiedDateTime'] as String?,
    );

Map<String, dynamic> _$$_SavedMemoModelToJson(_$_SavedMemoModel instance) =>
    <String, dynamic>{
      'memoId': instance.memoId,
      'title': instance.title,
      'author': instance.author,
      'content': instance.content,
      'madeDateTime': instance.madeDateTime,
      'modifiedDateTime': instance.modifiedDateTime,
    };
