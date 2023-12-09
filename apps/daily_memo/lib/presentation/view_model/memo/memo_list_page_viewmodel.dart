// import 'package:apps.daily_memo/core/route/app_routes.dart';
// import 'package:apps.daily_memo/core/route/routes_controller.dart';
// import 'package:apps.daily_memo/core/route/routes_controller_impl/routes_controller_go_router_impl.dart';
// import 'package:apps.daily_memo/domain/entity/memo/memo_info_entity.dart';
// import 'package:apps.daily_memo/domain/usecase/memo/memo_usecase.dart';
// import 'package:apps.daily_memo/presentation/state/common_state.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// class MemoListPageViewModel extends StateNotifier<CommonState<List<MemoInfoEntity>>> {
//   final MemoUseCase memoUseCase;
//
//   final RoutesController _routesController = RoutesControllerGoRouterImpl();
//
//   MemoListPageViewModel({
//     required this.memoUseCase,
//   }) : super(const CommonState.loading());
//
//   getMemoList() async {
//     final List<MemoInfoEntity> memoList = await memoUseCase.getAllMemoInfo;
//     state = CommonState.success(memoList);
//   }
//
//   void navigateToAddMemo(BuildContext context) =>
//       _routesController.toPushNamed(context, AppRoutes.MEMO.path);
//
//   void navigateToModifyMemo(BuildContext context, int memoId) {
//     _routesController.toPushNamed(
//       context,
//       AppRoutes.MEMO.path,
//       extra: {
//         "memoId": memoId,
//       },
//     );
//   }
//
//   Future<void> deleteMemo(
//     int memoId,
//     BuildContext context,
//   ) async {
//     if (!state.isLoading) state = const CommonState.loading();
//     final bool result = await memoUseCase.deleteMemo(memoId);
//     if (result) {
//       final List<MemoInfoEntity> memoList = await memoUseCase.getAllMemoInfo;
//       state = CommonState.success(memoList);
//       _routesController.pop(context);
//     } else {
//       state = CommonState.error(Exception());
//     }
//   }
// }
