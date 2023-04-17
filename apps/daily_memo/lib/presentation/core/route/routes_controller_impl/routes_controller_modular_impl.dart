// import 'dart:io';
//
// import 'package:apps.daily_memo/presentation/core/route/routes_controller.dart';
// import 'package:flutter/src/widgets/framework.dart';
// import 'package:flutter_modular/flutter_modular.dart';
//
// class RoutesControllerModularImpl extends RoutesController {
//   @override
//   void exitApp({int code = 0}) {
//     exit(code);
//   }
//
//   @override
//   void pop<T>(BuildContext context, {T? result}) {
//     if (Modular.to.canPop()) {
//       Modular.to.pop();
//     }
//   }
//
//   @override
//   void popUntil<T>(BuildContext context, String path, {T? result}) {
//     if (Modular.to.canPop()) {
//       Modular.to.popUntil((predictRoute) => predictRoute.settings.name == path);
//     }
//   }
//
//   @override
//   void popAllAndPush<T>(BuildContext context, String path, {T? result}) {
//     if (Modular.to.canPop()) {
//       Modular.to.pop();
//     }
//     Modular.to.pushNamed(path);
//   }
//
//   @override
//   void toNavigate<T>(BuildContext context, String path, {Map? extra}) {
//     Modular.to.navigate(path, arguments: extra);
//   }
//
//   @override
//   void toPushNamed<T>(BuildContext context, String path, {Map? extra}) {
//     Modular.to.pushNamed(path, arguments: extra);
//   }
// }
