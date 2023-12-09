import 'package:apps.daily_memo/data/model/memo/saved_memo_model.dart';
import 'package:apps.daily_memo/domain/entity/memo/memo_info_entity.dart';
import 'package:intl/intl.dart';

extension SaveMemoModelMapperToEntity on SavedMemoModel {
  MemoInfoEntity? get transferToMemoInfo {
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

      return MemoInfoEntity(
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
