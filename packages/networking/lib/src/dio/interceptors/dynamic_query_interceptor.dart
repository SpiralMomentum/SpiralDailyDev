import 'dart:async';

import 'package:dio/dio.dart';

class DynamicQueryInterceptor extends Interceptor {
  DynamicQueryInterceptor(this._builder);

  final FutureOr<Map<String, String>> Function() _builder;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final queries = await _builder();
    final current = Map<String, dynamic>.from(options.queryParameters);
    current.addAll(queries);
    options.queryParameters = current;
    handler.next(options);
  }
}
