// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_memo_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_AddMemoEntity _$$_AddMemoEntityFromJson(Map<String, dynamic> json) =>
    _$_AddMemoEntity(
      title: json['title'] as String?,
      author: json['author'] as String?,
      content: json['content'] as String?,
      madeDateTime: json['madeDateTime'] as String?,
      modifiedDateTime: json['modifiedDateTime'] as String?,
    );

Map<String, dynamic> _$$_AddMemoEntityToJson(_$_AddMemoEntity instance) =>
    <String, dynamic>{
      'title': instance.title,
      'author': instance.author,
      'content': instance.content,
      'madeDateTime': instance.madeDateTime,
      'modifiedDateTime': instance.modifiedDateTime,
    };
