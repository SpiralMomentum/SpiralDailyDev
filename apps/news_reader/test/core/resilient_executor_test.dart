import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';
import 'package:apps.news_reader/core/circuit_breaker/circuit_breaker.dart';
import 'package:apps.news_reader/core/resilient_executor.dart';

class MockCircuitBreaker extends Mock implements CircuitBreaker {}

void main() {
  late MockCircuitBreaker mockCb;
  late ResilientExecutor executor;

  setUp(() {
    mockCb = MockCircuitBreaker();
    executor = ResilientExecutor(circuitBreaker: mockCb);

    // 기본 stub: closed 상태
    when(() => mockCb.isOpen).thenReturn(false);
    when(() => mockCb.state).thenReturn(CircuitState.closed);
    when(() => mockCb.recordSuccess()).thenReturn(null);
    when(() => mockCb.recordFailure()).thenReturn(null);
  });

  group('ResilientExecutor', () {
    test('circuit breaker가 open이면 호출 없이 즉시 ErrorResult를 반환한다', () async {
      when(() => mockCb.isOpen).thenReturn(true);
      var callCount = 0;

      final result = await executor.run<String>(() async {
        callCount++;
        return const Success('ok');
      });

      expect(callCount, 0);
      expect(result, isA<ErrorResult<String>>());
      final error = result as ErrorResult<String>;
      expect(error.failure, isA<NetworkFailure>());
      expect(error.failure.message, contains('불안정'));
    });

    test('첫 시도에서 성공하면 recordSuccess를 호출한다', () async {
      final result = await executor.run<String>(() async {
        return const Success('data');
      });

      expect(result, isA<Success<String>>());
      expect((result as Success<String>).data, 'data');
      verify(() => mockCb.recordSuccess()).called(1);
      verifyNever(() => mockCb.recordFailure());
    });

    test('재시도 가능한 에러(timeout)는 maxRetries까지 재시도한다', () async {
      var callCount = 0;

      final result = await executor.run<String>(
        () async {
          callCount++;
          return const ErrorResult(
            NetworkFailure(message: 'connection timeout'),
          );
        },
        maxRetries: 2,
        initialDelay: const Duration(milliseconds: 1),
      );

      // 최초 1회 + 재시도 2회 = 총 3회
      expect(callCount, 3);
      expect(result, isA<ErrorResult<String>>());
      verify(() => mockCb.recordFailure()).called(3);
    });

    test('재시도 가능한 에러(5xx)는 maxRetries까지 재시도한다', () async {
      var callCount = 0;

      final result = await executor.run<String>(
        () async {
          callCount++;
          return const ErrorResult(
            NetworkFailure(message: 'server error 500'),
          );
        },
        maxRetries: 2,
        initialDelay: const Duration(milliseconds: 1),
      );

      expect(callCount, 3);
      expect(result, isA<ErrorResult<String>>());
    });

    test('재시도 불가능한 에러(4xx)는 재시도하지 않는다', () async {
      var callCount = 0;

      final result = await executor.run<String>(
        () async {
          callCount++;
          return const ErrorResult(
            NetworkFailure(message: '404 not found'),
          );
        },
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 1),
      );

      expect(callCount, 1);
      expect(result, isA<ErrorResult<String>>());
      verify(() => mockCb.recordFailure()).called(1);
    });

    test('NetworkFailure가 아닌 에러는 재시도하지 않는다', () async {
      var callCount = 0;

      final result = await executor.run<String>(
        () async {
          callCount++;
          return const ErrorResult(
            ParsingFailure(message: 'invalid json'),
          );
        },
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 1),
      );

      expect(callCount, 1);
      expect(result, isA<ErrorResult<String>>());
    });

    test('모든 재시도 소진 후 마지막 ErrorResult를 반환한다', () async {
      var callCount = 0;

      final result = await executor.run<String>(
        () async {
          callCount++;
          return ErrorResult(
            NetworkFailure(message: 'timeout attempt $callCount'),
          );
        },
        maxRetries: 2,
        initialDelay: const Duration(milliseconds: 1),
      );

      expect(callCount, 3);
      final error = result as ErrorResult<String>;
      expect(error.failure.message, contains('attempt 3'));
    });

    test('지수 백오프가 적용되어 지연 시간이 증가한다', () async {
      final timestamps = <DateTime>[];

      await executor.run<String>(
        () async {
          timestamps.add(DateTime.now());
          return const ErrorResult(
            NetworkFailure(message: 'timeout error'),
          );
        },
        maxRetries: 2,
        initialDelay: const Duration(milliseconds: 50),
        backoffMultiplier: 2.0,
      );

      // 3회 호출 (최초 + 재시도 2회)
      expect(timestamps.length, 3);

      // 첫 번째 재시도: initialDelay * 2^0 = 50ms
      final firstGap =
          timestamps[1].difference(timestamps[0]).inMilliseconds;
      // 두 번째 재시도: initialDelay * 2^1 = 100ms
      final secondGap =
          timestamps[2].difference(timestamps[1]).inMilliseconds;

      // 지수 백오프: 두 번째 간격이 첫 번째보다 커야 한다
      // 타이밍 오차를 감안하여 넉넉한 범위로 검증
      expect(firstGap, greaterThanOrEqualTo(30));
      expect(secondGap, greaterThanOrEqualTo(60));
      expect(secondGap, greaterThan(firstGap));
    });

    test('재시도 중 성공하면 recordSuccess를 호출하고 성공 결과를 반환한다', () async {
      var callCount = 0;

      final result = await executor.run<String>(
        () async {
          callCount++;
          if (callCount < 3) {
            return const ErrorResult(
              NetworkFailure(message: 'timeout'),
            );
          }
          return const Success('recovered');
        },
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 1),
      );

      expect(callCount, 3);
      expect(result, isA<Success<String>>());
      expect((result as Success<String>).data, 'recovered');
      // 실패 2회 + 성공 1회
      verify(() => mockCb.recordFailure()).called(2);
      verify(() => mockCb.recordSuccess()).called(1);
    });

    test('circuitBreaker getter가 주입된 인스턴스를 반환한다', () {
      expect(executor.circuitBreaker, same(mockCb));
    });
  });
}
