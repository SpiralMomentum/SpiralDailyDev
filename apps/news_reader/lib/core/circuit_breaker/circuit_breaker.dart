enum CircuitState { closed, open, halfOpen }

class CircuitBreaker {
  CircuitBreaker({
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 30),
  });

  final int failureThreshold;
  final Duration resetTimeout;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;

  CircuitState get state {
    if (_state == CircuitState.open && _lastFailureTime != null) {
      final elapsed = DateTime.now().difference(_lastFailureTime!);
      if (elapsed >= resetTimeout) {
        _state = CircuitState.halfOpen;
      }
    }
    return _state;
  }

  bool get isOpen => state == CircuitState.open;

  void recordSuccess() {
    _failureCount = 0;
    _state = CircuitState.closed;
  }

  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    if (_failureCount >= failureThreshold) {
      _state = CircuitState.open;
    }
  }

  void reset() {
    _failureCount = 0;
    _state = CircuitState.closed;
    _lastFailureTime = null;
  }
}
