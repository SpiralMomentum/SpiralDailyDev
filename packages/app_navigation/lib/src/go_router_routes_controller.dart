import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'routes_controller.dart';

/// Defines how navigation targets are interpreted when using [GoRouter].
enum GoRouterNavigationType {
  /// Treats the provided target as a concrete route path.
  path,

  /// Treats the provided target as a named route.
  name,
}

/// Strategy used when `popAllAndPush` is invoked.
enum GoRouterPopAllStrategy {
  /// Pops all routes and navigates using [GoRouter.go] / [GoRouter.goNamed].
  navigate,

  /// Pops all routes and pushes the next location on the stack.
  push,

  /// Uses [GoRouter.pushReplacement] when possible. Falls back to [navigate]
  /// if [GoRouterNavigationType.name] is used.
  pushReplacement,
}

/// Default implementation of [RoutesController] backed by [GoRouter].
class GoRouterRoutesController extends RoutesController {
  GoRouterRoutesController({
    required List<GoRoute> Function() routesBuilder,
    this.navigationType = GoRouterNavigationType.path,
    this.popAllStrategy = GoRouterPopAllStrategy.navigate,
  }) : _routesBuilder = routesBuilder;

  final List<GoRoute> Function() _routesBuilder;

  /// Determines whether navigation methods expect a route [path] or [name].
  final GoRouterNavigationType navigationType;

  /// Strategy applied when [RoutesController.popAllAndPush] is triggered.
  final GoRouterPopAllStrategy popAllStrategy;

  GoRouter _createRouter() => GoRouter(routes: _routesBuilder());

  @override
  void exitApp({int code = 0}) {
    exit(code);
  }

  @override
  void pop<T>(BuildContext context, {T? result}) {
    GoRouter.of(context).pop(result);
  }

  @override
  void popAllAndPush<T>(BuildContext context, String path, {T? result}) {
    switch (popAllStrategy) {
      case GoRouterPopAllStrategy.navigate:
        _popAll(context);
        _navigate(context, path);
        break;
      case GoRouterPopAllStrategy.push:
        _popAll(context);
        _push(context, path);
        break;
      case GoRouterPopAllStrategy.pushReplacement:
        if (navigationType == GoRouterNavigationType.name) {
          _popAll(context);
          _navigate(context, path);
        } else {
          context.pushReplacement(path);
        }
        break;
    }
  }

  @override
  void popUntil<T>(BuildContext context, String path, {T? result}) {
    final GoRouter router = _createRouter();
    while (router.canPop() && router.location != path) {
      GoRouter.of(context).pop(result);
    }
  }

  @override
  void toNavigate<T>(BuildContext context, String path, {Map? extra}) {
    _navigate(context, path, extra: extra);
  }

  @override
  void toPushNamed<T>(BuildContext context, String path, {Map? extra}) {
    _push(context, path, extra: extra);
  }

  void _navigate(BuildContext context, String path, {Map? extra}) {
    switch (navigationType) {
      case GoRouterNavigationType.path:
        context.go(path, extra: extra);
        break;
      case GoRouterNavigationType.name:
        context.goNamed(path, extra: extra);
        break;
    }
  }

  void _push(BuildContext context, String path, {Map? extra}) {
    switch (navigationType) {
      case GoRouterNavigationType.path:
        GoRouter.of(context).push(path, extra: extra);
        break;
      case GoRouterNavigationType.name:
        context.pushNamed(path, extra: extra);
        break;
    }
  }

  void _popAll(BuildContext context) {
    final GoRouter router = _createRouter();
    while (router.canPop()) {
      GoRouter.of(context).pop();
    }
  }
}
