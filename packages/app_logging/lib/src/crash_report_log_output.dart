import 'log_entry.dart';
import 'log_level.dart';
import 'log_output.dart';
import 'crash_reporter.dart';

/// error 레벨 이상의 로그를 [CrashReporter]에 자동 전달하는 출력 구현.
///
/// 일반 로그는 브레드크럼으로, 에러 로그는 recordError로 전달한다.
class CrashReportLogOutput extends LogOutput {
  const CrashReportLogOutput({
    this.errorThreshold = LogLevel.error,
  });

  /// 이 레벨 이상의 로그는 recordError로 전달.
  /// 미만의 로그는 브레드크럼(log)으로만 전달.
  final LogLevel errorThreshold;

  @override
  void write(LogEntry entry) {
    final reporter = CrashReporter.instance;

    if (entry.level.priority >= errorThreshold.priority &&
        entry.error != null) {
      reporter.recordError(
        entry.error!,
        entry.stackTrace,
        reason: '[${entry.tag}] ${entry.message}',
      );
    } else {
      reporter.log('[${entry.level.name.toUpperCase()}] [${entry.tag}] ${entry.message}');
    }
  }
}
