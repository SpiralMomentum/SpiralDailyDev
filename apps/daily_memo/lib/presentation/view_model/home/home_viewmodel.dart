import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';
import 'package:apps.daily_memo/domain/repository_interface/memo_repository.dart';
import 'package:apps.daily_memo/domain/usecase/memo_usecase.dart';
import 'package:apps.daily_memo/presentation/core/route/app_routes.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_controller.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_controller_impl/routes_controller_modular_impl.dart';
import 'package:flutter/cupertino.dart';

class HomeViewModel {
  late final MemoUsecase _memoUsecase;
  late final Stream<List<MemoListItem>> _memoList;
  final RoutesController routesController = RoutesControllerModularImpl();

  HomeViewModel({required MemoRepository memoRepository}) {
    _memoUsecase = MemoUsecase(memoRepository);
    _memoList = _memoUsecase.getMemoList.asStream();
  }

  /* TODO: bind 공통 ? 비동기
  * 1. 로컬 DB 데이터 불러오기
  * 2. SharedPreference 데이터 불러오기
  * */

  /* TODO: bind 로그인 연동이 되어있을 경우 ? 비동기
  * 1. 서버에서 데이터 불러오기
  *
  */
  Stream<List<MemoListItem>> get getMemos => _memoList;

  void navigateToAddMemo(BuildContext context) =>
      routesController.toPushNamed(context, AppRoutes.MEMO.path);
}
