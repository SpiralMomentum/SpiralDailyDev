import 'package:dio/dio.dart';
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
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;
  final String serviceKey;
  final String format;
  final String serviceName;

  @override
  Future<Result<Trades>> fetchInfo({
    required int startIndex,
    required int endIndex,
  }) async {
    try {
      final result = await _dio.get(
        '$baseUrl/$serviceKey/$format/$serviceName/$startIndex/$endIndex/',
        options: Options(responseType: ResponseType.json),
      );
      return Success(Trades.fromJson(result.data!));
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
          message: '전시 정보를 불러오지 못했습니다.',
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
