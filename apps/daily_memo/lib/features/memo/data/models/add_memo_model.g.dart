// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_memo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_AddMemoModel _$$_AddMemoModelFromJson(Map<String, dynamic> json) =>
    _$_AddMemoModel(
      title: json['title'] as String?,
      author: json['author'] as String?,
      content: json['content'] as String?,
      madeDateTime: json['madeDateTime'] as String?,
      modifiedDateTime: json['modifiedDateTime'] as String?,
    );

Map<String, dynamic> _$$_AddMemoModelToJson(_$_AddMemoModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'author': instance.author,
      'content': instance.content,
      'madeDateTime': instance.madeDateTime,
      'modifiedDateTime': instance.modifiedDateTime,
    };
