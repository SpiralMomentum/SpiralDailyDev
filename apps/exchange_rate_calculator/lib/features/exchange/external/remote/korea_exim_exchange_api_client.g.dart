// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'korea_exim_exchange_api_client.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers

class _KoreaEximExchangeApiClient implements KoreaEximExchangeApiClient {
  _KoreaEximExchangeApiClient(
    this._dio, {
    this.baseUrl,
  }) {
    baseUrl ??= 'https://www.koreaexim.go.kr/site/program/financial';
  }

  final Dio _dio;

  String? baseUrl;

  @override
  Future<List<KoreaEximExchangeInfoEntity>> getAllExchangeInfo(
    apiKey,
    searchDate,
    dataType,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'authkey': apiKey,
      r'searchdate': searchDate,
      r'data': dataType,
    };
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<List<dynamic>>(
        _setStreamType<List<KoreaEximExchangeInfoEntity>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/exchangeJSON',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    var value = _result.data!
        .map((dynamic i) =>
            KoreaEximExchangeInfoEntity.fromJson(i as Map<String, dynamic>))
        .toList();
    return value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }
}
