import 'package:apps.daily_memo/presentation/core/route/app_routes.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_controller.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_controller_impl/routes_controller_modular_impl.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class BottomBarViewModel{
  late List<BottomNavigationBarItem> _navigationItems;
  final BehaviorSubject<int> _currentIndex = BehaviorSubject.seeded(0);
  final RoutesController _routesController = RoutesControllerModularImpl();

  BottomBarViewModel({required List<BottomNavigationBarItem> items}){
    _navigationItems = items;
  }

  List<BottomNavigationBarItem> get navigationItems {
    return _navigationItems;
  }

  Stream<int> get currentIndexStream{
    return _currentIndex;
  }

  dynamic navigationItemOnTap(int tappedIndex, BuildContext context) async{
    if(tappedIndex == 0){
      _routesController.popAllAndPush(context, AppRoutes.HOME.path);
    }
    else if(tappedIndex == 1){
      // _routesController.popAllAndPush(context, AppRoutes.HOME.path);
    }
    _currentIndex.add(tappedIndex);
  }
}