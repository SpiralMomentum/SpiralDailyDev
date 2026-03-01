import 'package:test/test.dart';
import 'package:utils/result/failure.dart';

void main() {
  group('Failure subtypes', () {
    test('NetworkFailure stores message and code', () {
      const failure = NetworkFailure(
        message: 'timeout',
        code: 'TIMEOUT',
      );
      expect(failure.message, 'timeout');
      expect(failure.code, 'TIMEOUT');
      expect(failure.cause, isNull);
      expect(failure.stackTrace, isNull);
    });

    test('ParsingFailure stores cause', () {
      final cause = FormatException('bad json');
      final failure = ParsingFailure(
        message: 'parse error',
        cause: cause,
      );
      expect(failure.message, 'parse error');
      expect(failure.cause, cause);
    });

    test('LocalStorageFailure is a Failure', () {
      const failure = LocalStorageFailure(message: 'db locked');
      expect(failure, isA<Failure>());
      expect(failure.message, 'db locked');
    });

    test('BusinessRuleFailure is a Failure', () {
      const failure = BusinessRuleFailure(
        message: 'invalid state',
        code: 'INVALID_STATE',
      );
      expect(failure, isA<Failure>());
      expect(failure.code, 'INVALID_STATE');
    });
  });
}
