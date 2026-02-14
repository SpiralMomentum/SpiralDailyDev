import 'package:dio/dio.dart';
import 'package:networking/src/core/network_exception.dart';
import 'package:networking/src/core/network_failure.dart';
import 'package:networking/src/core/network_result.dart';
import 'package:networking/src/executor/network_executor.dart';
import 'package:test/test.dart';

void main() {
  group('NetworkExecutor.run', () {
    test('returns NetworkSuccess on successful call', () async {
      final result = await NetworkExecutor.run(() async => 'ok');
      expect(result, isA<NetworkSuccess<String>>());
      expect(result.dataOrNull, 'ok');
    });

    test('returns NetworkError with mapped failure on DioException', () async {
      final result = await NetworkExecutor.run<String>(() async {
        throw DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );
      });
      expect(result, isA<NetworkError<String>>());
      final error = (result as NetworkError<String>).error;
      expect(error.failure.type, NetworkFailureType.timeout);
    });

    test('returns NetworkError with unknown type on non-Dio exception',
        () async {
      final result = await NetworkExecutor.run<String>(() async {
        throw Exception('unexpected');
      });
      expect(result, isA<NetworkError<String>>());
      final error = (result as NetworkError<String>).error;
      expect(error.failure.type, NetworkFailureType.unknown);
      expect(error.cause, isA<Exception>());
    });

    test('preserves DioException as cause', () async {
      final dioException = DioException(
        type: DioExceptionType.receiveTimeout,
        requestOptions: RequestOptions(path: '/api'),
      );
      final result = await NetworkExecutor.run<int>(() async {
        throw dioException;
      });
      final error = (result as NetworkError<int>).error;
      expect(error, isA<NetworkException>());
      expect(error.cause, dioException);
    });
  });
}
