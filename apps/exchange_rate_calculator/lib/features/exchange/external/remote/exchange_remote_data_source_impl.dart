import 'package:dio/dio.dart';
import 'package:utils/utils.dart';

import 'package:exchange_rate_calculator/features/exchange/data/datasources/exchange_remote_data_source.dart';
import 'package:exchange_rate_calculator/features/exchange/data/exceptions/external_exception.dart';
import 'package:exchange_rate_calculator/features/exchange/data/models/github_exchange_response.dart';
import 'package:exchange_rate_calculator/features/exchange/external/remote/github_exchange_api_client.dart';

class ExchangeRemoteDataSourceImpl implements ExchangeRemoteDataSource {
  ExchangeRemoteDataSourceImpl({Dio? dio})
      : _client = GithubExchangeApiClient(dio ?? Dio());

  final GithubExchangeApiClient _client;

  @override
  Future<Result<GithubExchangeResponse>> fetchGithubExchange() async {
    try {
      final response = await _client.getAllExchangeInfo();
      return Success(response);
    } on DioException catch (error, stackTrace) {
      return ErrorResult(
        NetworkExternalException(
          _mapDioType(error.type),
          message: error.message,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      return ErrorResult(
        NetworkExternalException(
          NetworkExternalExceptionType.unknown,
          message: '환율 정보를 불러오지 못했습니다.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  NetworkExternalExceptionType _mapDioType(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkExternalExceptionType.timeout;
      case DioExceptionType.connectionError:
        return NetworkExternalExceptionType.noConnection;
      case DioExceptionType.badResponse:
        return NetworkExternalExceptionType.server;
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return NetworkExternalExceptionType.unknown;
    }
  }
}
