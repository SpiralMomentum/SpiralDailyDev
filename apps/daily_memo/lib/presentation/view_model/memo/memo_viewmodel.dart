// import 'package:apps.daily_memo/core/route/app_routes.dart';
// import 'package:apps.daily_memo/core/route/routes_controller.dart';
// import 'package:apps.daily_memo/core/route/routes_controller_impl/routes_controller_go_router_impl.dart';
// import 'package:apps.daily_memo/domain/entity/memo/memo_info_entity.dart';
// import 'package:apps.daily_memo/domain/usecase/memo/memo_usecase.dart';
// import 'package:apps.daily_memo/presentation/state/common_state.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// class MemoViewModel extends StateNotifier<CommonState<List<MemoInfoEntity>>> {
//   final MemoUseCase memoUseCase;
//   final RoutesController _routesController = RoutesControllerGoRouterImpl();
//
//   MemoViewModel({
//     int? memoId,
//     required this.memoUseCase,
//   }) : super(const CommonState.loading());
//
//   Future<void> getMemoInfoById(int? memoId) async {
//     MemoInfoEntity? memoInfo;
//     if (memoId != null) {
//       memoInfo = await memoUseCase.getMemoById(memoId);
//     }
//     final List<MemoInfoEntity> memoInfoList = memoInfo == null ? [] : [memoInfo];
//     state = CommonState.success(memoInfoList);
//   }
//
//   // TODO: SharedPreference
//   Future<void> addMemo(
//     String title,
//     String content,
//     BuildContext context,
//   ) async {
//     try {
//       if (!state.isLoading) {
//         state = const CommonState.loading();
//       }
//       final bool isSuccess = await memoUseCase.addMemo(
//         title: title,
//         content: content,
//       );
//       if (!isSuccess) {
//         state = CommonState.error(Exception());
//         return;
//       }
//       // final List<MemoInfoEntity> memoList = await memoUsecase.getAllMemoInfo;
//       _routesController.popAllAndPush(context, AppRoutes.HOME.path);
//     } on Exception catch (e) {
//       state = CommonState.error(e);
//     }
//   }
//
//   Future<void> modifyMemo(
//     int memoId,
//     String title,
//     String content,
//     String madeDateTime,
//     BuildContext context,
//   ) async {
//     try {
//       state = CommonState.loading();
//       final bool result = await memoUseCase.modifyMemo(
//         memoId: memoId,
//         title: title,
//         content: content,
//         madeDateTime: madeDateTime,
//       );
//       if (result == false) {
//         state = CommonState.error(Exception());
//         return;
//       }
//       // state = CommonState.success(MemoInfoList(values: [modifiedMemoInfo]));
//       // _routesController.popAllAndPush(context, AppRoutes.HOME.path);
//     } on Exception catch (e) {
//       state = CommonState.error(e);
//     }
//   }
// }
