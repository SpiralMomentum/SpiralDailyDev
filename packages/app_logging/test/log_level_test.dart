import 'package:app_logging/app_logging.dart';
import 'package:test/test.dart';

void main() {
  group('LogLevel', () {
    test('priority ordering: debug < info < warning < error', () {
      expect(LogLevel.debug.priority, lessThan(LogLevel.info.priority));
      expect(LogLevel.info.priority, lessThan(LogLevel.warning.priority));
      expect(LogLevel.warning.priority, lessThan(LogLevel.error.priority));
    });

    test('>= operator works correctly', () {
      expect(LogLevel.error >= LogLevel.debug, isTrue);
      expect(LogLevel.warning >= LogLevel.warning, isTrue);
      expect(LogLevel.debug >= LogLevel.info, isFalse);
    });

    test('compareTo returns correct ordering', () {
      expect(LogLevel.debug.compareTo(LogLevel.error), isNegative);
      expect(LogLevel.error.compareTo(LogLevel.debug), isPositive);
      expect(LogLevel.info.compareTo(LogLevel.info), isZero);
    });
  });
}
