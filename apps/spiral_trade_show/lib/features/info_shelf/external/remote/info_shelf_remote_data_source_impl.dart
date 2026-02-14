import 'package:app_logging/app_logging.dart';
import 'package:networking/networking.dart';
import 'package:utils/utils.dart';

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
    final networkResult = await NetworkExecutor.run(
      () async {
        final response = await _dio.get(
          '$baseUrl/$serviceKey/$format/$serviceName/$startIndex/$endIndex/',
          options: Options(responseType: ResponseType.json),
        );
        return Trades.fromJson(response.data!);
      },
    );

    return networkResult.when(
      success: (trades) => Success(trades),
      error: (networkException) {
        _logger.error(
          'API 호출 실패 [${networkException.failure.type.name}]: ${networkException.message}',
          error: networkException.cause,
        );
        return ErrorResult(
          NetworkExternalException(
            _mapFailureType(networkException.failure.type),
            message: networkException.message,
            cause: networkException.cause,
          ),
        );
      },
    );
  }

  /// NetworkFailureType을 기존 NetworkExternalExceptionType으로 매핑한다.
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
