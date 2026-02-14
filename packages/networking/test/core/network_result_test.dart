import 'package:networking/src/core/network_exception.dart';
import 'package:networking/src/core/network_failure.dart';
import 'package:networking/src/core/network_result.dart';
import 'package:test/test.dart';

void main() {
  group('NetworkSuccess', () {
    test('isSuccess returns true', () {
      const result = NetworkSuccess<int>(42);
      expect(result.isSuccess, isTrue);
      expect(result.isError, isFalse);
    });

    test('dataOrNull returns data', () {
      const result = NetworkSuccess<String>('response');
      expect(result.dataOrNull, 'response');
    });

    test('errorOrNull returns null', () {
      const result = NetworkSuccess<int>(1);
      expect(result.errorOrNull, isNull);
    });
  });

  group('NetworkError', () {
    final error = NetworkException(
      const NetworkFailure(
        type: NetworkFailureType.timeout,
        message: 'timeout',
      ),
    );

    test('isError returns true', () {
      final result = NetworkError<int>(error);
      expect(result.isError, isTrue);
      expect(result.isSuccess, isFalse);
    });

    test('dataOrNull returns null', () {
      final result = NetworkError<int>(error);
      expect(result.dataOrNull, isNull);
    });

    test('errorOrNull returns error', () {
      final result = NetworkError<int>(error);
      expect(result.errorOrNull, error);
    });
  });

  group('when', () {
    test('calls success branch on NetworkSuccess', () {
      const NetworkResult<int> result = NetworkSuccess(10);
      final value = result.when(
        success: (data) => 'data: $data',
        error: (err) => 'error',
      );
      expect(value, 'data: 10');
    });

    test('calls error branch on NetworkError', () {
      final exception = NetworkException(
        const NetworkFailure(
          type: NetworkFailureType.server,
          message: 'server error',
        ),
      );
      final NetworkResult<int> result = NetworkError(exception);
      final value = result.when(
        success: (data) => 'data: $data',
        error: (err) => 'error: ${err.message}',
      );
      expect(value, 'error: server error');
    });
  });

  group('map', () {
    test('transforms data on NetworkSuccess', () {
      const NetworkResult<int> result = NetworkSuccess(5);
      final mapped = result.map((v) => v * 3);
      expect(mapped.dataOrNull, 15);
    });

    test('propagates error on NetworkError', () {
      final exception = NetworkException(
        const NetworkFailure(
          type: NetworkFailureType.noConnection,
        ),
      );
      final NetworkResult<int> result = NetworkError(exception);
      final mapped = result.map((v) => v * 3);
      expect(mapped.isError, isTrue);
    });
  });

  group('flatMap', () {
    test('chains on NetworkSuccess', () {
      const NetworkResult<int> result = NetworkSuccess(3);
      final chained =
          result.flatMap((v) => NetworkSuccess('value: $v'));
      expect(chained.dataOrNull, 'value: 3');
    });

    test('short-circuits on NetworkError', () {
      final exception = NetworkException(
        const NetworkFailure(type: NetworkFailureType.cancelled),
      );
      final NetworkResult<int> result = NetworkError(exception);
      final chained =
          result.flatMap((v) => NetworkSuccess('value: $v'));
      expect(chained.isError, isTrue);
    });
  });
}
