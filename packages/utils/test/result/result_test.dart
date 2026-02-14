import 'package:flutter_test/flutter_test.dart';
import 'package:utils/result/failure.dart';
import 'package:utils/result/result.dart';

void main() {
  group('Success', () {
    test('isSuccess returns true', () {
      const result = Success<int>(42);
      expect(result.isSuccess, isTrue);
      expect(result.isError, isFalse);
    });

    test('dataOrNull returns data', () {
      const result = Success<String>('hello');
      expect(result.dataOrNull, 'hello');
    });

    test('failureOrNull returns null', () {
      const result = Success<int>(1);
      expect(result.failureOrNull, isNull);
    });
  });

  group('ErrorResult', () {
    const failure = NetworkFailure(message: 'timeout');

    test('isError returns true', () {
      const result = ErrorResult<int>(failure);
      expect(result.isError, isTrue);
      expect(result.isSuccess, isFalse);
    });

    test('dataOrNull returns null', () {
      const result = ErrorResult<int>(failure);
      expect(result.dataOrNull, isNull);
    });

    test('failureOrNull returns failure', () {
      const result = ErrorResult<int>(failure);
      expect(result.failureOrNull, failure);
    });
  });

  group('when', () {
    test('calls success branch on Success', () {
      const Result<int> result = Success(10);
      final value = result.when(
        success: (v) => 'got $v',
        error: (f) => 'error',
      );
      expect(value, 'got 10');
    });

    test('calls error branch on ErrorResult', () {
      const Result<int> result =
          ErrorResult(NetworkFailure(message: 'fail'));
      final value = result.when(
        success: (v) => 'got $v',
        error: (f) => 'error: ${f.message}',
      );
      expect(value, 'error: fail');
    });
  });

  group('map', () {
    test('transforms data on Success', () {
      const Result<int> result = Success(5);
      final mapped = result.map((v) => v * 2);
      expect(mapped.dataOrNull, 10);
    });

    test('propagates failure on ErrorResult', () {
      const failure = LocalStorageFailure(message: 'db error');
      const Result<int> result = ErrorResult(failure);
      final mapped = result.map((v) => v * 2);
      expect(mapped.isError, isTrue);
      expect(mapped.failureOrNull, failure);
    });
  });

  group('flatMap', () {
    test('chains on Success', () {
      const Result<int> result = Success(3);
      final chained = result.flatMap((v) => Success('value: $v'));
      expect(chained.dataOrNull, 'value: 3');
    });

    test('short-circuits on ErrorResult', () {
      const failure = BusinessRuleFailure(message: 'invalid');
      const Result<int> result = ErrorResult(failure);
      final chained = result.flatMap((v) => Success('value: $v'));
      expect(chained.isError, isTrue);
    });
  });

  group('mapError', () {
    test('transforms failure on ErrorResult', () {
      const Result<int> result =
          ErrorResult(NetworkFailure(message: 'original'));
      final mapped = result.mapError(
        (f) => ParsingFailure(message: 'mapped: ${f.message}'),
      );
      expect(mapped.isError, isTrue);
      expect(mapped.failureOrNull, isA<ParsingFailure>());
      expect(mapped.failureOrNull?.message, 'mapped: original');
    });

    test('passes through on Success', () {
      const Result<int> result = Success(42);
      final mapped = result.mapError(
        (f) => ParsingFailure(message: 'should not reach'),
      );
      expect(mapped.dataOrNull, 42);
    });
  });

  group('fold', () {
    test('delegates to when', () {
      const Result<int> result = Success(7);
      final value = result.fold(
        onSuccess: (v) => v + 1,
        onError: (f) => -1,
      );
      expect(value, 8);
    });
  });

  group('guard', () {
    test('returns Success on normal execution', () {
      final result = guard(
        action: () => 42,
        onError: (e, s) => const ParsingFailure(message: 'parse error'),
      );
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 42);
    });

    test('returns ErrorResult on exception', () {
      final result = guard<int>(
        action: () => throw FormatException('bad'),
        onError: (e, s) => ParsingFailure(message: e.toString()),
      );
      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<ParsingFailure>());
    });
  });

  group('guardAsync', () {
    test('returns Success on normal execution', () async {
      final result = await guardAsync(
        action: () async => 'async value',
        onError: (e, s) => const NetworkFailure(message: 'fail'),
      );
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, 'async value');
    });

    test('returns ErrorResult on async exception', () async {
      final result = await guardAsync<String>(
        action: () async => throw Exception('async fail'),
        onError: (e, s) => NetworkFailure(message: e.toString()),
      );
      expect(result.isError, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });
}
