import 'package:app_logging/app_logging.dart';
import 'package:test/test.dart';

void main() {
  group('LogEntry.format', () {
    test('includes timestamp, level, tag, and message', () {
      final entry = LogEntry(
        level: LogLevel.info,
        tag: 'MemoBloc',
        message: 'event received',
        timestamp: DateTime(2025, 1, 15, 10, 30),
      );

      final formatted = entry.format();

      expect(formatted, contains('[INFO]'));
      expect(formatted, contains('[MemoBloc]'));
      expect(formatted, contains('event received'));
      expect(formatted, contains('2025-01-15'));
    });

    test('includes error when present', () {
      final entry = LogEntry(
        level: LogLevel.error,
        tag: 'Repo',
        message: 'failed',
        timestamp: DateTime(2025, 1, 1),
        error: Exception('db locked'),
      );

      expect(entry.format(), contains('error: Exception: db locked'));
    });

    test('includes stackTrace when present', () {
      final stack = StackTrace.current;
      final entry = LogEntry(
        level: LogLevel.error,
        tag: 'Repo',
        message: 'failed',
        timestamp: DateTime(2025, 1, 1),
        stackTrace: stack,
      );

      expect(entry.format(), contains('stackTrace:'));
    });
  });
}
