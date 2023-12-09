import 'dart:io';

import 'package:apps.daily_memo/core/route/app_routes.dart';
import 'package:apps.daily_memo/core/route/routes_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoutesControllerGoRouterImpl extends RoutesController {
  @override
  void exitApp({int code = 0}) {
    exit(code);
  }

  @override
  void pop<T>(BuildContext context, {T? result}) {
    GoRouter.of(context).pop();
  }

  @override
  void popUntil<T>(BuildContext context, String path, {T? result}) {
    final GoRouter temp =
        GoRouter(routes: AppRoutes.values.map((e) => e.getRouter).toList());
    while (temp.canPop() && temp.location != path) {
      context.pop();
    }
  }

  @override
  void popAllAndPush<T>(BuildContext context, String path, {T? result}) {
    context.pushReplacement(path);
  }

  @override
  void toNavigate<T>(BuildContext context, String path, {Map? extra}) {
    context.go(path, extra: extra);
  }

  @override
  void toPushNamed<T>(BuildContext context, String path, {Map? extra}) {
    GoRouter.of(context).push(path, extra: extra);
  }
}
