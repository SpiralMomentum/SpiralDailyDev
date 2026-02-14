import 'package:dio/dio.dart';
import 'package:networking/src/core/network_failure.dart';
import 'package:networking/src/dio/dio_error_mapper.dart';
import 'package:test/test.dart';

void main() {
  RequestOptions requestOptions() => RequestOptions(path: '/test');

  group('mapDioError', () {
    test('connectionTimeout maps to timeout', () {
      final exception = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: requestOptions(),
      );
      final failure = mapDioError(exception);
      expect(failure.type, NetworkFailureType.timeout);
    });

    test('sendTimeout maps to timeout', () {
      final exception = DioException(
        type: DioExceptionType.sendTimeout,
        requestOptions: requestOptions(),
      );
      final failure = mapDioError(exception);
      expect(failure.type, NetworkFailureType.timeout);
    });

    test('receiveTimeout maps to timeout', () {
      final exception = DioException(
        type: DioExceptionType.receiveTimeout,
        requestOptions: requestOptions(),
      );
      final failure = mapDioError(exception);
      expect(failure.type, NetworkFailureType.timeout);
    });

    test('connectionError maps to noConnection', () {
      final exception = DioException(
        type: DioExceptionType.connectionError,
        requestOptions: requestOptions(),
      );
      final failure = mapDioError(exception);
      expect(failure.type, NetworkFailureType.noConnection);
    });

    test('cancel maps to cancelled', () {
      final exception = DioException(
        type: DioExceptionType.cancel,
        requestOptions: requestOptions(),
      );
      final failure = mapDioError(exception);
      expect(failure.type, NetworkFailureType.cancelled);
    });

    test('unknown maps to unknown', () {
      final exception = DioException(
        type: DioExceptionType.unknown,
        requestOptions: requestOptions(),
        message: 'something went wrong',
      );
      final failure = mapDioError(exception);
      expect(failure.type, NetworkFailureType.unknown);
      expect(failure.message, 'something went wrong');
    });

    test('unknown with null message uses fallback', () {
      final exception = DioException(
        type: DioExceptionType.unknown,
        requestOptions: requestOptions(),
      );
      final failure = mapDioError(exception);
      expect(failure.type, NetworkFailureType.unknown);
      expect(failure.message, contains('알 수 없는'));
    });

    group('badResponse status code mapping', () {
      DioException badResponse(int statusCode) {
        return DioException(
          type: DioExceptionType.badResponse,
          requestOptions: requestOptions(),
          response: Response(
            requestOptions: requestOptions(),
            statusCode: statusCode,
            data: 'error body',
          ),
        );
      }

      test('401 maps to unauthorized', () {
        final failure = mapDioError(badResponse(401));
        expect(failure.type, NetworkFailureType.unauthorized);
        expect(failure.statusCode, 401);
      });

      test('403 maps to forbidden', () {
        final failure = mapDioError(badResponse(403));
        expect(failure.type, NetworkFailureType.forbidden);
        expect(failure.statusCode, 403);
      });

      test('404 maps to notFound', () {
        final failure = mapDioError(badResponse(404));
        expect(failure.type, NetworkFailureType.notFound);
        expect(failure.statusCode, 404);
      });

      test('500 maps to server', () {
        final failure = mapDioError(badResponse(500));
        expect(failure.type, NetworkFailureType.server);
        expect(failure.statusCode, 500);
      });

      test('503 maps to server', () {
        final failure = mapDioError(badResponse(503));
        expect(failure.type, NetworkFailureType.server);
      });

      test('400 maps to client', () {
        final failure = mapDioError(badResponse(400));
        expect(failure.type, NetworkFailureType.client);
        expect(failure.statusCode, 400);
      });

      test('rawBody is captured', () {
        final failure = mapDioError(badResponse(500));
        expect(failure.rawBody, 'error body');
      });
    });

    test('badResponse with null statusCode maps to unknown', () {
      final exception = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: requestOptions(),
        response: Response(
          requestOptions: requestOptions(),
          statusCode: null,
        ),
      );
      final failure = mapDioError(exception);
      expect(failure.type, NetworkFailureType.unknown);
    });
  });
}
