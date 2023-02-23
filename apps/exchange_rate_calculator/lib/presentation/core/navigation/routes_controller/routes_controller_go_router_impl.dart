import 'dart:io';

import 'package:exchange_rate_calculator/presentation/core/navigation/routes/app_routes.dart';
import 'package:exchange_rate_calculator/presentation/core/navigation/routes/app_routes_go_router.dart';
import 'package:exchange_rate_calculator/presentation/core/navigation/routes_controller/routes_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoutesControllerGoRouterImpl extends RoutesController {
  @override
  void exitApp({int code = 0}) {
    exit(code);
  }

  @override
  void pop<T>(BuildContext context, {T? result}) {
    context.pop();
  }

  @override
  void popUntil<T>(BuildContext context, String path, {T? result}) {
    final GoRouter _temp =
        GoRouter(routes: AppRoutes.values.map((e) => e.getRouter).toList());
    while (_temp.canPop() && _temp.location != path) {
      context.pop();
    }
  }

  @override
  void popAllAndPush<T>(BuildContext context, String path, {T? result}) {
    final GoRouter _temp =
        GoRouter(routes: AppRoutes.values.map((e) => e.getRouter).toList());

    while (_temp.canPop()) {
      context.pop();
    }

    context.pushNamed(path);
  }

  @override
  void toNavigate<T>(BuildContext context, String path, {Map? extra}) {
    context.goNamed(path, extra: extra);
  }

  @override
  void toPushNamed<T>(BuildContext context, String path, {Map? extra}) {
    context.pushNamed(path, extra: extra);
  }
}
