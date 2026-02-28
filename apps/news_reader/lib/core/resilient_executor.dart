import 'dart:math' as math;
import 'package:utils/result/result.dart';
import 'package:utils/result/failure.dart';
import 'circuit_breaker/circuit_breaker.dart';

/// Retry with Exponential Backoff + Circuit Breaker 통합
class ResilientExecutor {
  ResilientExecutor({CircuitBreaker? circuitBreaker})
    : _circuitBreaker = circuitBreaker ?? CircuitBreaker();

  final CircuitBreaker _circuitBreaker;

  /// 네트워크 호출을 재시도 + 서킷 브레이커로 보호하여 실행
  /// - maxRetries: 최대 재시도 횟수 (기본 3)
  /// - initialDelay: 초기 지연 시간 (기본 1초)
  /// - backoffMultiplier: 지수 배율 (기본 2)
  Future<Result<T>> run<T>(
    Future<Result<T>> Function() call, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
  }) async {
    if (_circuitBreaker.isOpen) {
      return const ErrorResult(NetworkFailure(
        message: '서비스가 일시적으로 불안정합니다.',
      ));
    }

    Result<T>? lastResult;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      lastResult = await call();
      if (lastResult is Success<T>) {
        _circuitBreaker.recordSuccess();
        return lastResult;
      }
      _circuitBreaker.recordFailure();
      if (attempt < maxRetries && _shouldRetry(lastResult)) {
        final delayMs = initialDelay.inMilliseconds *
            math.pow(backoffMultiplier, attempt).toInt();
        await Future.delayed(Duration(milliseconds: delayMs));
      } else {
        break;
      }
    }
    return lastResult!;
  }

  bool _shouldRetry(Result result) {
    if (result case ErrorResult(:final failure)) {
      if (failure is NetworkFailure) {
        final msg = failure.message?.toLowerCase() ?? '';
        return msg.contains('timeout') || msg.contains('5');
      }
    }
    return false;
  }

  CircuitBreaker get circuitBreaker => _circuitBreaker;
}
