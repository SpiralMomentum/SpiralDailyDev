import 'package:meta/meta.dart';

import 'log_level.dart';

/// 하나의 로그 이벤트를 나타내는 불변 구조체.
@immutable
class LogEntry {
  const LogEntry({
    required this.level,
    required this.tag,
    required this.message,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  final LogLevel level;

  /// 로그 출처를 식별하는 태그 (예: 클래스명, 기능명).
  final String tag;

  final String message;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;

  /// 구조화된 문자열로 포맷팅.
  /// `[2025-01-15T10:30:00.000] [WARNING] [MemoBloc] 메모 저장 실패`
  String format() {
    final buffer = StringBuffer()
      ..write('[${timestamp.toIso8601String()}] ')
      ..write('[${level.name.toUpperCase()}] ')
      ..write('[$tag] ')
      ..write(message);

    if (error != null) {
      buffer.write('\n  error: $error');
    }
    if (stackTrace != null) {
      buffer.write('\n  stackTrace: $stackTrace');
    }
    return buffer.toString();
  }

  @override
  String toString() => format();
}
