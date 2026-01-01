import 'dart:async';

typedef HeadersBuilder = FutureOr<Map<String, String>> Function();
typedef QueryParametersBuilder = FutureOr<Map<String, String>> Function();

class NetworkOptions {
  const NetworkOptions({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 15),
    this.defaultHeaders = const {},
    this.defaultQueryParameters = const {},
    this.dynamicHeaders,
    this.dynamicQueryParameters,
    this.enableLogging = false,
  });

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final Map<String, String> defaultHeaders;
  final Map<String, String> defaultQueryParameters;
  final HeadersBuilder? dynamicHeaders;
  final QueryParametersBuilder? dynamicQueryParameters;
  final bool enableLogging;
}
