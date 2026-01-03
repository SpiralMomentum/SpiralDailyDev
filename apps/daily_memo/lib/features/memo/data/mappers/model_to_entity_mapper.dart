import 'package:apps.daily_memo/features/memo/data/models/saved_memo_model.dart';
import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:intl/intl.dart';

extension SaveMemoModelMapperToEntity on SavedMemoModel {
  MemoInfoEntity? get transferToMemoInfo {
    if (madeDateTime == null ||
        modifiedDateTime == null ||
        title == null ||
        content == null) return null;
    try {
      final DateTime calendarTime =
          DateFormat("yyyy-MM-dd").parse(modifiedDateTime!);
      final DateTime madeTime =
          DateFormat("yyyy-MM-dd hh:mm:ss").parse(madeDateTime!);
      final DateTime modifiedTime =
          DateFormat("yyyy-MM-dd hh:mm:ss").parse(modifiedDateTime!);

      return MemoInfoEntity(
        uniqueId: memoId,
        calendarDateTime: calendarTime,
        memoMadeDateTime: madeTime,
        memoModifiedDateTime: modifiedTime,
        title: title!,
        content: content!,
      );
    } catch (e) {
      return null;
    }
  }
}
