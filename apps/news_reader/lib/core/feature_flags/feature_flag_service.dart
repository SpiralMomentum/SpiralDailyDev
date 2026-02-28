/// Feature Flag 평가 서비스 인터페이스.
///
/// Firebase Remote Config 등 원격 구성 시스템과 동일한 계약을 정의한다.
/// 구현체를 교체하면 원격/로컬 전환이 가능하다.
abstract class FeatureFlagService {
  /// [flagName]에 해당하는 bool 플래그가 켜져 있는지 반환한다.
  bool isEnabled(String flagName);

  /// [key]에 해당하는 문자열 값을 반환한다.
  String getString(String key, {String defaultValue = ''});

  /// [key]에 해당하는 정수 값을 반환한다.
  int getInt(String key, {int defaultValue = 0});

  /// 원격 설정을 가져와 활성화한다.
  Future<void> fetchAndActivate();
}

/// 로컬 기본값 기반 [FeatureFlagService] 구현.
///
/// 네트워크 없이도 동작하는 오프라인 폴백용이다.
/// 생성 시 [defaults]를 넘기면 기본값 맵을 덮어쓴다.
class LocalFeatureFlagService implements FeatureFlagService {
  LocalFeatureFlagService({Map<String, dynamic>? defaults})
      : _flags = defaults ?? Map<String, dynamic>.from(_defaultFlags);

  final Map<String, dynamic> _flags;

  static const Map<String, dynamic> _defaultFlags = {
    'sdui_feed': false,
    'new_comment_ui': false,
    'show_search': true,
    'feed_layout_variant': 'A',
    'max_comments_per_page': 50,
  };

  @override
  bool isEnabled(String flagName) => _flags[flagName] as bool? ?? false;

  @override
  String getString(String key, {String defaultValue = ''}) {
    final value = _flags[key];
    if (value is String) return value;
    return defaultValue;
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    final value = _flags[key];
    if (value is int) return value;
    return defaultValue;
  }

  @override
  Future<void> fetchAndActivate() async {
    // 로컬 전용이므로 no-op. 원격 구현체에서 오버라이드한다.
  }
}
