import 'dart:async';

import 'log_entry.dart';

/// 로그 출력 대상 추상 인터페이스.
///
/// 콘솔 출력, 파일 기록, 외부 서비스(Crashlytics/Sentry) 전송 등
/// 다양한 구현체로 교체 가능.
abstract class LogOutput {
  const LogOutput();

  FutureOr<void> write(LogEntry entry);
}

/// 기본 콘솔 출력 구현.
class ConsoleLogOutput extends LogOutput {
  const ConsoleLogOutput();

  @override
  void write(LogEntry entry) {
    // ignore: avoid_print
    print(entry.format());
  }
}

/// 테스트/캡처용 버퍼 출력 구현.
class BufferLogOutput extends LogOutput {
  final List<LogEntry> entries = [];

  @override
  void write(LogEntry entry) {
    entries.add(entry);
  }

  void clear() => entries.clear();
}
