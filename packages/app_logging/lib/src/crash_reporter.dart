import 'dart:async';

/// 크래시 리포팅 추상 인터페이스.
///
/// 앱에서 Firebase Crashlytics, Sentry 등 구체적인 구현체를 주입한다.
///
/// 사용법:
/// ```dart
/// // 앱 초기화 시
/// CrashReporter.instance = FirebaseCrashReporter();
///
/// // 에러 발생 시 자동 리포트
/// CrashReporter.instance.recordError(error, stackTrace);
/// ```
abstract class CrashReporter {
  const CrashReporter();

  /// 전역 인스턴스. 앱 시작 시 구체 구현체로 교체한다.
  /// 기본값은 아무 동작도 하지 않는 [NoOpCrashReporter].
  static CrashReporter instance = const NoOpCrashReporter();

  /// 비치명적 에러를 기록한다.
  FutureOr<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  });

  /// 사용자 식별 정보를 설정한다 (크래시 리포트에 포함).
  FutureOr<void> setUserId(String id);

  /// 커스텀 키-값 쌍을 크래시 리포트에 첨부한다.
  FutureOr<void> setCustomKey(String key, Object value);

  /// 브레드크럼 로그를 남긴다 (크래시 발생 전 맥락 정보).
  FutureOr<void> log(String message);
}

/// 아무 동작도 하지 않는 기본 구현. 크래시 리포팅이 설정되지 않은 경우 사용.
class NoOpCrashReporter extends CrashReporter {
  const NoOpCrashReporter();

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) {}

  @override
  void setUserId(String id) {}

  @override
  void setCustomKey(String key, Object value) {}

  @override
  void log(String message) {}
}
