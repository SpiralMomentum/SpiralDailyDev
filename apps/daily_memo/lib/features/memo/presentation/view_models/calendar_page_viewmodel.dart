// import 'package:apps.daily_memo/domain/entity/memo/memo_info_entity.dart';
// import 'package:apps.daily_memo/domain/usecase/memo/memo_usecase.dart';
// import 'package:apps.daily_memo/presentation/state/common_state.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
//
// class CalendarPageViewModel
//     extends StateNotifier<CommonState<Map<DateTime, List<MemoInfoEntity>>>> {
//   final MemoUseCase memoUseCase;
//
//   CalendarPageViewModel(this.memoUseCase) : super(const CommonState.loading());
//
//   getAllEvents() async {
//     Map<DateTime, List<MemoInfoEntity>> result = {};
//     final List<MemoInfoEntity> memoInfoList = await memoUseCase.getAllMemoInfo;
//     for (MemoInfoEntity memoInfo in memoInfoList) {
//       final calendarDateTime = DateTime.parse(
//           DateFormat("yyyy-MM-dd").format(memoInfo.memoModifiedDateTime));
//
//       if (result.containsKey(calendarDateTime)) {
//         final List<MemoInfoEntity> memos = result[calendarDateTime]!;
//         memos.add(memoInfo);
//         result[calendarDateTime] = memos;
//       } else {
//         result[calendarDateTime] = [memoInfo];
//       }
//     }
//
//     state = CommonState.success(result);
//   }
// }
