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

/// Strategy used when `RoutesController.replaceAllWith` is invoked.
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
    this.navigationType = GoRouterNavigationType.path,
    this.popAllStrategy = GoRouterPopAllStrategy.navigate,
  });

  /// Determines whether navigation methods expect a route [path] or [name].
  final GoRouterNavigationType navigationType;

  /// Strategy applied when [RoutesController.replaceAllWith] is triggered.
  final GoRouterPopAllStrategy popAllStrategy;

  @override
  void exitApp({int code = 0}) {
    exit(code);
  }

  @override
  bool pop<T>(BuildContext context, {T? result}) {
    if (!canPop(context)) {
      return false;
    }

    GoRouter.of(context).pop(result);
    return true;
  }

  @override
  Future<T?>? replaceAllWith<T>(
    BuildContext context,
    String target, {
    Object? extra,
  }) {
    switch (popAllStrategy) {
      case GoRouterPopAllStrategy.navigate:
        _popAll(context);
        return _navigate<T>(context, target, extra: extra);
      case GoRouterPopAllStrategy.push:
        _popAll(context);
        return _push<T>(context, target, extra: extra);
      case GoRouterPopAllStrategy.pushReplacement:
        if (navigationType == GoRouterNavigationType.name) {
          _popAll(context);
          return _navigate<T>(context, target, extra: extra);
        } else {
          return context.pushReplacement<T>(target, extra: extra);
        }
    }
  }

  @override
  void popUntil<T>(BuildContext context, String target, {T? result}) {
    while (canPop(context) && GoRouter.of(context).location != target) {
      GoRouter.of(context).pop(result);
    }
  }

  @override
  Future<T?>? navigateTo<T>(
    BuildContext context,
    String target, {
    Object? extra,
  }) {
    return _navigate<T>(context, target, extra: extra);
  }

  @override
  Future<T?>? push<T>(
    BuildContext context,
    String target, {
    Object? extra,
  }) {
    return _push<T>(context, target, extra: extra);
  }

  @override
  bool canPop(BuildContext context) => GoRouter.of(context).canPop();

  @override
  String? currentLocation(BuildContext context) => GoRouter.of(context).location;

  Future<T?>? _navigate<T>(
    BuildContext context,
    String target, {
    Object? extra,
  }) {
    switch (navigationType) {
      case GoRouterNavigationType.path:
        context.go(target, extra: extra);
        return null;
      case GoRouterNavigationType.name:
        context.goNamed(target, extra: extra);
        return null;
    }
  }

  Future<T?>? _push<T>(
    BuildContext context,
    String target, {
    Object? extra,
  }) {
    switch (navigationType) {
      case GoRouterNavigationType.path:
        return GoRouter.of(context).push<T>(target, extra: extra);
      case GoRouterNavigationType.name:
        return context.pushNamed<T>(target, extra: extra);
    }
  }

  void _popAll(BuildContext context) {
    while (canPop(context)) {
      GoRouter.of(context).pop();
    }
  }
}
