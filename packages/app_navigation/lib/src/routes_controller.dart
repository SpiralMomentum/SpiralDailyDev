import 'dart:async';

import 'package:flutter/widgets.dart';

/// Contract for coordinating navigation from feature layers without
/// depending on the concrete routing solution.
///
/// The interface intentionally focuses on the minimal behaviour any
/// implementation must provide so that feature layers can rely on a
/// consistent API regardless of the underlying navigation package.
abstract class RoutesController {
  /// Replaces the current location with [target].
  ///
  /// Returns a [FutureOr] that resolves when the operation completes. Some
  /// navigation systems (such as [GoRouter.go]) complete synchronously while
  /// others might expose asynchronous handles.
  FutureOr<T?>? navigateTo<T>(
    BuildContext context,
    String target, {
    Object? extra,
  });

  /// Pushes [target] on top of the current navigation stack.
  FutureOr<T?>? push<T>(
    BuildContext context,
    String target, {
    Object? extra,
  });

  /// Attempts to pop the current location.
  ///
  /// Returns `true` when the pop operation has been executed.
  bool pop<T>(
    BuildContext context, {
    T? result,
  });

  /// Pops locations until [target] becomes the current location.
  void popUntil<T>(
    BuildContext context,
    String target, {
    T? result,
  });

  /// Clears the stack and navigates to [target].
  FutureOr<T?>? replaceAllWith<T>(
    BuildContext context,
    String target, {
    Object? extra,
  });

  /// Whether the current stack can be popped.
  bool canPop(BuildContext context);

  /// Returns the active navigation location if available.
  String? currentLocation(BuildContext context);

  /// Exit the application process with the given [code].
  void exitApp({int code = 0});
}
