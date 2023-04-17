import 'package:apps.daily_memo/domain/model/home/memo_info.dart';
import 'package:apps.daily_memo/domain/model/home/memo_info_list.dart';

abstract class MemoRepository {
  // Future<List<MemoListItem>> get getMemoList;
  Future<MemoInfoList> get getAllMemoInfo;

  Future<MemoInfo?> getMemoInfoById(int memoId);

  // Future<List<CalendarEvent>> getEvents(DateTime dateTime);
  // Future<Map<DateTime, List<CalendarEvent>>> get getAllEvents;

  Future<bool> addMemo({
    required String title,
    required String content,
  });

  Future<MemoInfo?> modifyMemo({
    required int memoId,
    required String title,
    required String content,
    required String madeDateTime,
  });

  Future<bool> deleteMemo(int memoId);
}
