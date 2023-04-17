import 'package:apps.daily_memo/data/entity/saved_memo_entity.dart';
import 'package:apps.daily_memo/domain/model/home/memo_info.dart';
import 'package:intl/intl.dart';

extension SaveMemoEntityMapper on SavedMemoEntity {
  MemoInfo? get transferToMemoInfo {
    if (madeDateTime == null ||
        modifiedDateTime == null ||
        title == null ||
        content == null) return null;
    try {
      final DateTime _calendarDateTime =
          DateFormat("yyyy-MM-dd").parse(modifiedDateTime!);
      final DateTime _madeDateTime =
          DateFormat("yyyy-MM-dd hh:mm:ss").parse(madeDateTime!);
      final DateTime _modifiedDateTime =
          DateFormat("yyyy-MM-dd hh:mm:ss").parse(modifiedDateTime!);

      return MemoInfo(
        uniqueId: memoId,
        calendarDateTime: _calendarDateTime,
        memoMadeDateTime: _madeDateTime,
        memoModifiedDateTime: _modifiedDateTime,
        title: title!,
        content: content!,
      );
    } catch (e) {
      return null;
    }
  }
}
