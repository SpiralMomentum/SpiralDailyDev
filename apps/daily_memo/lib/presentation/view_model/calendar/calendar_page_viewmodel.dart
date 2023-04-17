import 'package:apps.daily_memo/domain/model/home/memo_info.dart';
import 'package:apps.daily_memo/domain/usecase/memo/memo_usecase.dart';
import 'package:apps.daily_memo/presentation/state/common_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CalendarPageViewModel
    extends StateNotifier<CommonState<Map<DateTime, List<MemoInfo>>>> {
  final MemoUsecase memoUsecase;

  CalendarPageViewModel(this.memoUsecase) : super(const CommonState.loading());

  getAllEvents() async {
    Map<DateTime, List<MemoInfo>> result = {};
    final memoInfoList = await memoUsecase.getAllMemoInfo;
    List<MemoInfo> memoInfos = memoInfoList.values;
    for (MemoInfo memoInfo in memoInfos) {
      final calendarDateTime = DateTime.parse(
          DateFormat("yyyy-MM-dd").format(memoInfo.memoModifiedDateTime));

      if (result.containsKey(calendarDateTime)) {
        final List<MemoInfo> memos = result[calendarDateTime]!;
        memos.add(memoInfo);
        result[calendarDateTime] = memos;
      } else {
        result[calendarDateTime] = [memoInfo];
      }
    }

    state = CommonState.success(result);
  }
}
