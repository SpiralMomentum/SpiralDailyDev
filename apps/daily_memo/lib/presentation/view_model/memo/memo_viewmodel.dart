import 'package:apps.daily_memo/domain/model/memo/memo_model.dart';
import 'package:apps.daily_memo/domain/repository_interface/memo_repository.dart';
import 'package:apps.daily_memo/domain/usecase/memo_usecase.dart';
import 'package:apps.daily_memo/presentation/core/route/app_routes.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_controller.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_controller_impl/routes_controller_modular_impl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MemoViewModel {
  late final MemoUsecase _memoUsecase;
  late final MemoModel? _existedMemo;
  final RoutesController routesController = RoutesControllerModularImpl();

  MemoViewModel(
      {MemoModel? memoModel, required MemoRepository memoRepository}) {
    _existedMemo = memoModel;
    _memoUsecase = MemoUsecase(memoRepository);
  }


  bool get isAddMemo => _existedMemo == null;

  bool get isModifiedMemo => _existedMemo != null;

  String get beforeTitle => _existedMemo?.title ?? "";

  String get beforeContent => _existedMemo?.content ?? "";

  // TODO: callback
  // TODO: SharedPreference
  Future<void> addMemo(String title, String content,
      BuildContext context) async {
    try {
      await _memoUsecase.addMemo(MemoModel(title, content));
      routesController.toPushNamed(context, AppRoutes.HOME.path);
    } catch (e) {
      showDialog(context: context, builder: (_) => Container(child: Text("실패"),));
    }
  }
}
