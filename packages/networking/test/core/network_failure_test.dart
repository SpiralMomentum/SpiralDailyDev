import 'package:networking/src/core/network_failure.dart';
import 'package:test/test.dart';

void main() {
  group('NetworkFailure', () {
    test('stores type and message', () {
      const failure = NetworkFailure(
        type: NetworkFailureType.timeout,
        message: 'timed out',
      );
      expect(failure.type, NetworkFailureType.timeout);
      expect(failure.message, 'timed out');
      expect(failure.statusCode, isNull);
      expect(failure.rawBody, isNull);
    });

    test('stores statusCode and rawBody', () {
      const failure = NetworkFailure(
        type: NetworkFailureType.server,
        statusCode: 500,
        rawBody: '{"error":"internal"}',
      );
      expect(failure.statusCode, 500);
      expect(failure.rawBody, '{"error":"internal"}');
    });

    test('toString includes type, statusCode and message', () {
      const failure = NetworkFailure(
        type: NetworkFailureType.unauthorized,
        statusCode: 401,
        message: 'invalid token',
      );
      final str = failure.toString();
      expect(str, contains('unauthorized'));
      expect(str, contains('401'));
      expect(str, contains('invalid token'));
    });
  });

  group('NetworkFailureType', () {
    test('has all expected values', () {
      expect(NetworkFailureType.values, containsAll([
        NetworkFailureType.timeout,
        NetworkFailureType.noConnection,
        NetworkFailureType.server,
        NetworkFailureType.client,
        NetworkFailureType.unauthorized,
        NetworkFailureType.forbidden,
        NetworkFailureType.notFound,
        NetworkFailureType.serialization,
        NetworkFailureType.cancelled,
        NetworkFailureType.unknown,
      ]));
    });
  });
}
