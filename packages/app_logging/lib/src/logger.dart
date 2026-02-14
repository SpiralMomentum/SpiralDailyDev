import 'log_entry.dart';
import 'log_level.dart';
import 'log_output.dart';
import 'sanitizer.dart';

/// 구조화된 로거.
///
/// 사용법:
/// ```dart
/// final logger = AppLogger(tag: 'MemoBloc');
/// logger.debug('이벤트 수신: GetAllMemos');
/// logger.error('메모 저장 실패', error: failure);
/// ```
///
/// 전역 설정:
/// ```dart
/// AppLogger.minimumLevel = LogLevel.warning;  // warning 이상만 출력
/// AppLogger.outputs = [ConsoleLogOutput()];
/// AppLogger.sanitizer = LogSanitizer(patterns: LogSanitizer.defaultPatterns);
/// ```
class AppLogger {
  AppLogger({required this.tag});

  final String tag;

  /// 전역 최소 출력 레벨. 이 레벨 미만의 로그는 무시된다.
  static LogLevel minimumLevel = LogLevel.debug;

  /// 로그 출력 대상 목록. 복수 대상에 동시 출력 가능.
  static List<LogOutput> outputs = [const ConsoleLogOutput()];

  /// 민감 정보 마스킹. null이면 마스킹하지 않는다.
  static LogSanitizer? sanitizer;

  void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.debug, message, error: error, stackTrace: stackTrace);

  void info(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.info, message, error: error, stackTrace: stackTrace);

  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.warning, message, error: error, stackTrace: stackTrace);

  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, message, error: error, stackTrace: stackTrace);

  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.priority < minimumLevel.priority) return;

    final sanitized = sanitizer?.sanitize(message) ?? message;

    final entry = LogEntry(
      level: level,
      tag: tag,
      message: sanitized,
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );

    for (final output in outputs) {
      output.write(entry);
    }
  }
}
