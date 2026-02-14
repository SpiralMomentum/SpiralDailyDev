import 'package:app_logging/app_logging.dart';
import 'package:test/test.dart';

void main() {
  group('LogSanitizer', () {
    const sanitizer = LogSanitizer(
      patterns: LogSanitizer.defaultPatterns,
    );

    test('masks Bearer tokens', () {
      final result = sanitizer.sanitize(
        'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.payload.sig',
      );
      expect(result, contains('Bearer ***'));
      expect(result, isNot(contains('eyJ')));
    });

    test('masks email addresses', () {
      final result = sanitizer.sanitize('user: john@example.com logged in');
      expect(result, contains('***@***.***'));
      expect(result, isNot(contains('john@example.com')));
    });

    test('masks password JSON fields', () {
      final result = sanitizer.sanitize(
        '{"username": "test", "password": "secret123"}',
      );
      expect(result, contains('"password": "***"'));
      expect(result, isNot(contains('secret123')));
    });

    test('masks apiKey JSON fields', () {
      final result = sanitizer.sanitize(
        '{"apiKey": "abc-123-def"}',
      );
      expect(result, contains('"apiKey": "***"'));
      expect(result, isNot(contains('abc-123-def')));
    });

    test('masks token JSON fields', () {
      final result = sanitizer.sanitize(
        '{"token": "refresh_tok_xyz"}',
      );
      expect(result, contains('"token": "***"'));
    });

    test('leaves non-sensitive content unchanged', () {
      const input = 'User pressed button, memo count: 5';
      expect(sanitizer.sanitize(input), input);
    });

    test('empty patterns returns input unchanged', () {
      const empty = LogSanitizer(patterns: []);
      expect(
        empty.sanitize('Bearer secret'),
        'Bearer secret',
      );
    });
  });
}
