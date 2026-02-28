import 'package:dio/dio.dart';
import 'package:networking/src/core/network_failure.dart';
import 'package:networking/src/executor/network_executor.dart';
import 'package:test/test.dart';
import 'package:utils/result/result.dart';

void main() {
  group('NetworkExecutor.run', () {
    test('returns Success on successful call', () async {
      final result = await NetworkExecutor.run(() async => 'ok');
      expect(result, isA<Success<String>>());
      expect(result.dataOrNull, 'ok');
    });

    test('returns ErrorResult with mapped failure on DioException', () async {
      final result = await NetworkExecutor.run<String>(() async {
        throw DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );
      });
      expect(result, isA<ErrorResult<String>>());
      final failure = result.failureOrNull as NetworkFailure;
      expect(failure.type, NetworkFailureType.timeout);
    });

    test('returns ErrorResult with unknown type on non-Dio exception',
        () async {
      final result = await NetworkExecutor.run<String>(() async {
        throw Exception('unexpected');
      });
      expect(result, isA<ErrorResult<String>>());
      final failure = result.failureOrNull as NetworkFailure;
      expect(failure.type, NetworkFailureType.unknown);
      expect(failure.cause, isA<Exception>());
    });

    test('preserves DioException as cause', () async {
      final dioException = DioException(
        type: DioExceptionType.receiveTimeout,
        requestOptions: RequestOptions(path: '/api'),
      );
      final result = await NetworkExecutor.run<int>(() async {
        throw dioException;
      });
      final failure = result.failureOrNull as NetworkFailure;
      expect(failure.cause, dioException);
    });

    test('captures stackTrace on DioException', () async {
      final result = await NetworkExecutor.run<int>(() async {
        throw DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );
      });
      final failure = result.failureOrNull as NetworkFailure;
      expect(failure.stackTrace, isNotNull);
    });

    test('captures stackTrace on general exception', () async {
      final result = await NetworkExecutor.run<int>(() async {
        throw Exception('unexpected');
      });
      final failure = result.failureOrNull as NetworkFailure;
      expect(failure.stackTrace, isNotNull);
    });
  });
}
