import 'package:flutter/foundation.dart';

@immutable
class MemoInfo {
  final int uniqueId;
  final DateTime calendarDateTime;
  final DateTime memoMadeDateTime;
  final DateTime memoModifiedDateTime;
  final String title;
  final String content;

  const MemoInfo({
    required this.uniqueId,
    required this.calendarDateTime,
    required this.memoMadeDateTime,
    required this.memoModifiedDateTime,
    required this.title,
    required this.content,
  });

  
}
