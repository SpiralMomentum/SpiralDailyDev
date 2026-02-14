/// 민감 정보 마스킹 유틸리티.
///
/// 로그 메시지에 포함될 수 있는 토큰, 비밀번호, 이메일 등을
/// 기록 전에 마스킹 처리한다.
class LogSanitizer {
  const LogSanitizer({
    this.patterns = const [],
  });

  /// 기본 민감 정보 패턴 (이메일, Bearer 토큰, password 필드).
  static const defaultPatterns = [
    // Bearer 토큰
    SanitizePattern(
      pattern: r'Bearer\s+[A-Za-z0-9\-._~+/]+=*',
      replacement: 'Bearer ***',
    ),
    // password JSON 값
    SanitizePattern(
      pattern: r'"password"\s*:\s*"[^"]*"',
      replacement: '"password": "***"',
    ),
    // secret JSON 값
    SanitizePattern(
      pattern: r'"secret"\s*:\s*"[^"]*"',
      replacement: '"secret": "***"',
    ),
    // token JSON 값
    SanitizePattern(
      pattern: r'"token"\s*:\s*"[^"]*"',
      replacement: '"token": "***"',
    ),
    // apiKey JSON 값
    SanitizePattern(
      pattern: r'"apiKey"\s*:\s*"[^"]*"',
      replacement: '"apiKey": "***"',
    ),
    // api_key JSON 값
    SanitizePattern(
      pattern: r'"api_key"\s*:\s*"[^"]*"',
      replacement: '"api_key": "***"',
    ),
    // 이메일
    SanitizePattern(
      pattern: r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
      replacement: '***@***.***',
    ),
  ];

  final List<SanitizePattern> patterns;

  /// [input] 문자열에서 모든 패턴을 적용하여 마스킹된 문자열을 반환.
  String sanitize(String input) {
    var result = input;
    for (final p in patterns) {
      result = result.replaceAll(RegExp(p.pattern), p.replacement);
    }
    return result;
  }
}

/// 마스킹할 정규식 패턴과 대체 문자열 쌍.
class SanitizePattern {
  const SanitizePattern({
    required this.pattern,
    required this.replacement,
  });

  final String pattern;
  final String replacement;
}
