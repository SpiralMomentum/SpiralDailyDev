import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class MemoInfoEntity extends Equatable {
  final int uniqueId;
  final DateTime calendarDateTime;
  final DateTime memoMadeDateTime;
  final DateTime memoModifiedDateTime;
  final String title;
  final String content;

  const MemoInfoEntity({
    required this.uniqueId,
    required this.calendarDateTime,
    required this.memoMadeDateTime,
    required this.memoModifiedDateTime,
    required this.title,
    required this.content,
  });

  @override
  List<Object?> get props => [
        uniqueId,
        calendarDateTime,
        memoMadeDateTime,
        memoModifiedDateTime,
        title,
        content,
      ];
}
