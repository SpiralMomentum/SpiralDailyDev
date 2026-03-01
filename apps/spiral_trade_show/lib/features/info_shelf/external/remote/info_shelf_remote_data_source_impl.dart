import 'package:app_logging/app_logging.dart';
import 'package:networking/networking.dart';

import 'package:spiral_trade_show/features/info_shelf/data/datasources/info_shelf_remote_data_source.dart';
import 'package:spiral_trade_show/features/info_shelf/data/exceptions/external_exception.dart';
import 'package:spiral_trade_show/features/info_shelf/models/model/trades.dart';

class InfoShelfRemoteDataSourceImpl implements InfoShelfRemoteDataSource {
  InfoShelfRemoteDataSourceImpl({
    Dio? dio,
    required this.baseUrl,
    required this.serviceKey,
    required this.format,
    required this.serviceName,
  }) : _dio = dio ??
            DioProvider(
              options: NetworkOptions(baseUrl: ''),
            ).create();

  final Dio _dio;
  final String baseUrl;
  final String serviceKey;
  final String format;
  final String serviceName;
  final _logger = AppLogger(tag: 'InfoShelfDataSource');

  @override
  Future<Result<Trades>> fetchInfo({
    required int startIndex,
    required int endIndex,
  }) async {
    final result = await NetworkExecutor.run(
      () async {
        final response = await _dio.get(
          '$baseUrl/$serviceKey/$format/$serviceName/$startIndex/$endIndex/',
          options: Options(responseType: ResponseType.json),
        );
        return Trades.fromJson(response.data!);
      },
    );

    return result.when(
      success: (trades) => Success(trades),
      error: (failure) {
        if (failure is NetworkFailure) {
          _logger.error(
            'API 호출 실패 [${failure.type.name}]: ${failure.message}',
            error: failure.cause,
          );
          return ErrorResult(
            NetworkExternalException(
              _mapFailureType(failure.type),
              message: failure.message,
              cause: failure.cause,
            ),
          );
        }
        return ErrorResult(
          NetworkExternalException(
            NetworkExternalExceptionType.unknown,
            message: failure.message,
            cause: failure.cause,
          ),
        );
      },
    );
  }

  NetworkExternalExceptionType _mapFailureType(NetworkFailureType type) {
    switch (type) {
      case NetworkFailureType.timeout:
        return NetworkExternalExceptionType.timeout;
      case NetworkFailureType.noConnection:
        return NetworkExternalExceptionType.noConnection;
      case NetworkFailureType.server:
      case NetworkFailureType.client:
      case NetworkFailureType.unauthorized:
      case NetworkFailureType.forbidden:
      case NetworkFailureType.notFound:
        return NetworkExternalExceptionType.server;
      case NetworkFailureType.serialization:
      case NetworkFailureType.cancelled:
      case NetworkFailureType.unknown:
        return NetworkExternalExceptionType.unknown;
    }
  }
}
