abstract class CrashlyticsService {
  void recordError(Object error, StackTrace? stackTrace, {bool fatal = false});
  void log(String message);
  void setUserId(String id);
}

class MockCrashlyticsService implements CrashlyticsService {
  final List<String> logs = [];

  @override
  void recordError(Object error, StackTrace? stackTrace,
      {bool fatal = false}) {
    logs.add('error: $error');
  }

  @override
  void log(String message) {
    logs.add(message);
  }

  @override
  void setUserId(String id) {}
}
