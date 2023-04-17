import 'package:apps.daily_memo/presentation/core/route/app_routes.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_controller.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_controller_impl/routes_controller_modular_impl.dart';
import 'package:apps.daily_memo/presentation/state/common_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomBarViewModel extends StateNotifier<CommonState<int>> {
  final List<BottomNavigationBarItem> navigationItems;

  BottomBarViewModel(
    this.navigationItems,
  ) : super(const CommonState.init(0));


  navigationItemOnTap(int tappedIndex) async {
    state = CommonState.success(tappedIndex);
  }
}
