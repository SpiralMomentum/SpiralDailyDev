import 'package:apps.daily_memo/domain/model/home/memo_info.dart';
import 'package:apps.daily_memo/domain/model/home/memo_info_list.dart';
import 'package:apps.daily_memo/domain/usecase/memo/memo_usecase.dart';
import 'package:apps.daily_memo/presentation/core/route/app_routes.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_controller.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_controller_impl/routes_controller_go_router_impl.dart';
import 'package:apps.daily_memo/presentation/state/common_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemoViewModel extends StateNotifier<CommonState<MemoInfoList?>> {
  final MemoUsecase memoUsecase;
  final RoutesController _routesController = RoutesControllerGoRouterImpl();

  MemoViewModel({
    int? memoId,
    required this.memoUsecase,
  }) : super(const CommonState.loading());

  Future<void> getMemoInfoById(int? memoId) async {
    MemoInfo? memoInfo;
    if (memoId != null) {
      memoInfo = await memoUsecase.getMemoById(memoId);
    }
    final memoInfoList = MemoInfoList(values: memoInfo == null ? [] : [memoInfo]);
    state = CommonState.success(memoInfoList);
  }

  // TODO: SharedPreference
  Future<void> addMemo(
    String title,
    String content,
    BuildContext context,
  ) async {
    try {
      if (!state.isLoading) {
        state = const CommonState.loading();
      }
      final bool isSuccess = await memoUsecase.addMemo(
        title: title,
        content: content,
      );
      if (!isSuccess) {
        state = CommonState.error(Exception());
        return;
      }
      final MemoInfoList memoList = await memoUsecase.getAllMemoInfo;
      state = CommonState.success(memoList);
      _routesController.popAllAndPush(context, AppRoutes.HOME.path);
    } on Exception catch (e) {
      state = CommonState.error(e);
    }
  }

  Future<void> modifyMemo(
    int memoId,
    String title,
    String content,
    String madeDateTime,
    BuildContext context,
  ) async {
    try {
      state = CommonState.loading();
      final MemoInfo? modifiedMemoInfo = await memoUsecase.modifyMemo(
        memoId: memoId,
        title: title,
        content: content,
        madeDateTime: madeDateTime,
      );
      if (modifiedMemoInfo == null) {
        state = CommonState.error(Exception());
        return;
      }
      state = CommonState.success(MemoInfoList(values: [modifiedMemoInfo]));
      _routesController.popAllAndPush(context, AppRoutes.HOME.path);
    } on Exception catch (e) {
      state = CommonState.error(e);
    }
  }
}
