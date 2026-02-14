import 'package:app_logging/app_logging.dart';
import 'package:test/test.dart';

class FakeCrashReporter extends CrashReporter {
  final List<String> logs = [];
  final List<(Object, StackTrace?, String?)> errors = [];
  String? userId;
  final Map<String, Object> customKeys = {};

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    errors.add((error, stackTrace, reason));
  }

  @override
  void setUserId(String id) => userId = id;

  @override
  void setCustomKey(String key, Object value) => customKeys[key] = value;

  @override
  void log(String message) => logs.add(message);
}

void main() {
  late FakeCrashReporter fakeReporter;

  setUp(() {
    fakeReporter = FakeCrashReporter();
    CrashReporter.instance = fakeReporter;
  });

  tearDown(() {
    CrashReporter.instance = const NoOpCrashReporter();
  });

  group('CrashReporter', () {
    test('default instance is NoOpCrashReporter', () {
      CrashReporter.instance = const NoOpCrashReporter();
      // Should not throw
      CrashReporter.instance.recordError(Exception('test'), null);
      CrashReporter.instance.log('test');
      CrashReporter.instance.setUserId('u1');
      CrashReporter.instance.setCustomKey('k', 'v');
    });

    test('recordError captures error and reason', () {
      final error = Exception('crash');
      CrashReporter.instance.recordError(
        error,
        StackTrace.empty,
        reason: 'test reason',
      );

      expect(fakeReporter.errors, hasLength(1));
      expect(fakeReporter.errors.first.$1, error);
      expect(fakeReporter.errors.first.$3, 'test reason');
    });

    test('setUserId stores user id', () {
      CrashReporter.instance.setUserId('user-123');
      expect(fakeReporter.userId, 'user-123');
    });

    test('setCustomKey stores key-value pair', () {
      CrashReporter.instance.setCustomKey('app_version', '1.0.0');
      expect(fakeReporter.customKeys['app_version'], '1.0.0');
    });

    test('log records breadcrumb message', () {
      CrashReporter.instance.log('navigated to home');
      expect(fakeReporter.logs, contains('navigated to home'));
    });
  });

  group('CrashReportLogOutput', () {
    test('sends error-level logs with error to recordError', () {
      const output = CrashReportLogOutput();
      final error = Exception('boom');

      output.write(LogEntry(
        level: LogLevel.error,
        tag: 'MemoBloc',
        message: 'save failed',
        timestamp: DateTime(2025, 1, 1),
        error: error,
      ));

      expect(fakeReporter.errors, hasLength(1));
      expect(fakeReporter.errors.first.$3, contains('MemoBloc'));
      expect(fakeReporter.errors.first.$3, contains('save failed'));
    });

    test('sends non-error logs as breadcrumbs', () {
      const output = CrashReportLogOutput();

      output.write(LogEntry(
        level: LogLevel.info,
        tag: 'Nav',
        message: 'page opened',
        timestamp: DateTime(2025, 1, 1),
      ));

      expect(fakeReporter.logs, hasLength(1));
      expect(fakeReporter.logs.first, contains('[Nav]'));
    });

    test('sends error-level logs without error object as breadcrumbs', () {
      const output = CrashReportLogOutput();

      output.write(LogEntry(
        level: LogLevel.error,
        tag: 'Test',
        message: 'something wrong',
        timestamp: DateTime(2025, 1, 1),
      ));

      // No error object -> goes to log, not recordError
      expect(fakeReporter.errors, isEmpty);
      expect(fakeReporter.logs, hasLength(1));
    });
  });
}
