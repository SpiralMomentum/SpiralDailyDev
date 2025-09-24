import 'package:flutter/widgets.dart';

/// Abstraction for navigation behaviours used across the apps.
abstract class RoutesController {
  void toNavigate<T>(
    BuildContext context,
    String path, {
    Map<dynamic, dynamic>? extra,
  });

  void toPushNamed<T>(
    BuildContext context,
    String path, {
    Map<dynamic, dynamic>? extra,
  });

  void pop<T>(
    BuildContext context, {
    T? result,
  });

  void popUntil<T>(
    BuildContext context,
    String path, {
    T? result,
  });

  void popAllAndPush<T>(
    BuildContext context,
    String path, {
    T? result,
  });

  void exitApp({int code = 0});
}
