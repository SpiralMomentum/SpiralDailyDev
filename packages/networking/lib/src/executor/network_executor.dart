import 'package:dio/dio.dart';

import '../core/network_failure.dart';
import '../core/network_exception.dart';
import '../core/network_result.dart';
import '../dio/dio_error_mapper.dart';

typedef NetworkCall<T> = Future<T> Function();

class NetworkExecutor {
  const NetworkExecutor._();

  static Future<NetworkResult<T>> run<T>(NetworkCall<T> call) async {
    try {
      final response = await call();
      return NetworkSuccess<T>(response);
    } on DioException catch (error) {
      final failure = mapDioError(error);
      return NetworkError<T>(NetworkException(failure, cause: error));
    } catch (error) {
      return NetworkError<T>(
        NetworkException(
          const NetworkFailure(
            type: NetworkFailureType.unknown,
            message: '알 수 없는 오류가 발생했습니다.',
          ),
          cause: error,
        ),
      );
    }
  }
}
