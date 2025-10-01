import 'package:flutter/widgets.dart';

/// Contract for coordinating navigation from feature layers without
/// depending on the concrete routing solution.
abstract class RoutesController {
  /// Navigate to the provided [path] replacing the current location.
  void toNavigate<T>(
    BuildContext context,
    String path, {
    Map<dynamic, dynamic>? extra,
  });

  /// Push a new location identified by [path] while keeping the current stack.
  void toPushNamed<T>(
    BuildContext context,
    String path, {
    Map<dynamic, dynamic>? extra,
  });

  /// Pop the current location.
  void pop<T>(
    BuildContext context, {
    T? result,
  });

  /// Pop locations until [path] is reached.
  void popUntil<T>(
    BuildContext context,
    String path, {
    T? result,
  });

  /// Remove every location and push the provided [path].
  void popAllAndPush<T>(
    BuildContext context,
    String path, {
    T? result,
  });

  /// Exit the application process with the given [code].
  void exitApp({int code = 0});
}
