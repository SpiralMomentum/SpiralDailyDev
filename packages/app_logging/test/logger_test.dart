import 'package:app_logging/app_logging.dart';
import 'package:test/test.dart';

void main() {
  late BufferLogOutput buffer;

  setUp(() {
    buffer = BufferLogOutput();
    AppLogger.minimumLevel = LogLevel.debug;
    AppLogger.outputs = [buffer];
    AppLogger.sanitizer = null;
  });

  group('AppLogger', () {
    test('logs debug message', () {
      final logger = AppLogger(tag: 'Test');
      logger.debug('hello');

      expect(buffer.entries, hasLength(1));
      expect(buffer.entries.first.level, LogLevel.debug);
      expect(buffer.entries.first.tag, 'Test');
      expect(buffer.entries.first.message, 'hello');
    });

    test('logs info message', () {
      final logger = AppLogger(tag: 'Test');
      logger.info('info msg');

      expect(buffer.entries.first.level, LogLevel.info);
    });

    test('logs warning message', () {
      final logger = AppLogger(tag: 'Test');
      logger.warning('warn msg');

      expect(buffer.entries.first.level, LogLevel.warning);
    });

    test('logs error with error object and stackTrace', () {
      final logger = AppLogger(tag: 'Test');
      final error = Exception('boom');
      final stack = StackTrace.current;

      logger.error('failed', error: error, stackTrace: stack);

      expect(buffer.entries.first.level, LogLevel.error);
      expect(buffer.entries.first.error, error);
      expect(buffer.entries.first.stackTrace, stack);
    });

    test('filters by minimumLevel', () {
      AppLogger.minimumLevel = LogLevel.warning;
      final logger = AppLogger(tag: 'Test');

      logger.debug('should be filtered');
      logger.info('should be filtered');
      logger.warning('should pass');
      logger.error('should pass');

      expect(buffer.entries, hasLength(2));
      expect(buffer.entries[0].level, LogLevel.warning);
      expect(buffer.entries[1].level, LogLevel.error);
    });

    test('writes to multiple outputs', () {
      final buffer2 = BufferLogOutput();
      AppLogger.outputs = [buffer, buffer2];
      final logger = AppLogger(tag: 'Multi');

      logger.info('to both');

      expect(buffer.entries, hasLength(1));
      expect(buffer2.entries, hasLength(1));
    });

    test('applies sanitizer to message', () {
      AppLogger.sanitizer = const LogSanitizer(
        patterns: LogSanitizer.defaultPatterns,
      );
      final logger = AppLogger(tag: 'Auth');

      logger.info('token: Bearer eyJhbGciOiJIUzI1NiJ9.test');

      expect(buffer.entries.first.message, contains('Bearer ***'));
      expect(buffer.entries.first.message, isNot(contains('eyJ')));
    });

    test('does not sanitize when sanitizer is null', () {
      AppLogger.sanitizer = null;
      final logger = AppLogger(tag: 'Test');

      logger.info('Bearer secret123');

      expect(buffer.entries.first.message, 'Bearer secret123');
    });
  });
}
