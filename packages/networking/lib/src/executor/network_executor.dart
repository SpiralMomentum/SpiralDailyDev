import 'package:dio/dio.dart';
import 'package:utils/result/result.dart';

import '../core/network_failure.dart';
import '../dio/dio_error_mapper.dart';

typedef NetworkCall<T> = Future<T> Function();

class NetworkExecutor {
  const NetworkExecutor._();

  static Future<Result<T>> run<T>(NetworkCall<T> call) async {
    try {
      final response = await call();
      return Success<T>(response);
    } on DioException catch (error, stackTrace) {
      final failure = mapDioError(error);
      return ErrorResult<T>(
        NetworkFailure(
          type: failure.type,
          message: failure.message,
          statusCode: failure.statusCode,
          rawBody: failure.rawBody,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      return ErrorResult<T>(
        NetworkFailure(
          type: NetworkFailureType.unknown,
          message: '알 수 없는 오류가 발생했습니다.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
