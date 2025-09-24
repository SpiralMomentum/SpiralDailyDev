import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'routes_controller.dart';

/// [RoutesController] implementation backed by [GoRouter].
class GoRouterRoutesController extends RoutesController {
  const GoRouterRoutesController();

  GoRouter _router(BuildContext context) => GoRouter.of(context);

  @override
  void exitApp({int code = 0}) {
    exit(code);
  }

  @override
  void pop<T>(BuildContext context, {T? result}) {
    _router(context).pop(result);
  }

  @override
  void popUntil<T>(BuildContext context, String path, {T? result}) {
    _router(context).go(path);
  }

  @override
  void popAllAndPush<T>(BuildContext context, String path, {T? result}) {
    _router(context).go(path);
  }

  @override
  void toNavigate<T>(
    BuildContext context,
    String path, {
    Map<dynamic, dynamic>? extra,
  }) {
    _router(context).go(path, extra: extra);
  }

  @override
  void toPushNamed<T>(
    BuildContext context,
    String path, {
    Map<dynamic, dynamic>? extra,
  }) {
    _router(context).push(path, extra: extra);
  }
}
