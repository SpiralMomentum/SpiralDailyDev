import 'package:flutter/cupertino.dart';

// TODO: route 재점검
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
    String path,
  );

  void exitApp({int code});
}
