import 'dart:async';

import 'package:dio/dio.dart';

class DynamicHeadersInterceptor extends Interceptor {
  DynamicHeadersInterceptor(this._builder);

  final FutureOr<Map<String, String>> Function() _builder;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final headers = await _builder();
    options.headers.addAll(headers);
    handler.next(options);
  }
}
