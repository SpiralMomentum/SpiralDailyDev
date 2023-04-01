// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_memo_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_SavedMemoEntity _$$_SavedMemoEntityFromJson(Map<String, dynamic> json) =>
    _$_SavedMemoEntity(
      memoId: json['memoId'] as int,
      title: json['title'] as String?,
      author: json['author'] as String?,
      content: json['content'] as String?,
      madeDateTime: json['madeDateTime'] as String?,
      modifiedDateTime: json['modifiedDateTime'] as String?,
    );

Map<String, dynamic> _$$_SavedMemoEntityToJson(_$_SavedMemoEntity instance) =>
    <String, dynamic>{
      'memoId': instance.memoId,
      'title': instance.title,
      'author': instance.author,
      'content': instance.content,
      'madeDateTime': instance.madeDateTime,
      'modifiedDateTime': instance.modifiedDateTime,
    };
