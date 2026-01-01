import 'package:dio/dio.dart';

import 'interceptors/dynamic_headers_interceptor.dart';
import 'interceptors/dynamic_query_interceptor.dart';
import 'network_options.dart';

class DioProvider {
  DioProvider({
    required NetworkOptions options,
    List<Interceptor> interceptors = const [],
  })  : _options = options,
        _extraInterceptors = interceptors;

  final NetworkOptions _options;
  final List<Interceptor> _extraInterceptors;

  Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _options.baseUrl,
        connectTimeout: _options.connectTimeout,
        receiveTimeout: _options.receiveTimeout,
        sendTimeout: _options.sendTimeout,
        headers: Map.unmodifiable(_options.defaultHeaders),
        queryParameters: Map.unmodifiable(_options.defaultQueryParameters),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    if (_options.dynamicHeaders != null) {
      dio.interceptors.add(
        DynamicHeadersInterceptor(_options.dynamicHeaders!),
      );
    }
    if (_options.dynamicQueryParameters != null) {
      dio.interceptors.add(
        DynamicQueryInterceptor(_options.dynamicQueryParameters!),
      );
    }

    dio.interceptors.addAll(_extraInterceptors);

    if (_options.enableLogging) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
        ),
      );
    }

    return dio;
  }
}
