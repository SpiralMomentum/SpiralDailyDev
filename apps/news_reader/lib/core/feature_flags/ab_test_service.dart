import 'feature_flag_service.dart';

/// A/B Testing 분배 서비스.
///
/// [FeatureFlagService]를 기반으로 실험 변형(variant)과
/// 실험 활성화 여부를 조회한다.
///
/// 실험명 규칙:
/// - 변형값 키: 실험명 그대로 (예: `feed_layout_variant`)
/// - 활성화 키: `experiment_` 접두사 + 실험명 (예: `experiment_feed_layout`)
class AbTestService {
  AbTestService(this._featureFlagService);

  final FeatureFlagService _featureFlagService;

  /// 현재 사용자의 [experimentName] 실험 변형을 반환한다.
  ///
  /// 설정이 없으면 `'control'`을 반환한다.
  String getVariant(String experimentName) {
    return _featureFlagService.getString(
      experimentName,
      defaultValue: 'control',
    );
  }

  /// [experimentName] 실험이 활성화되어 있는지 반환한다.
  ///
  /// 내부적으로 `experiment_<experimentName>` 플래그를 확인한다.
  bool isExperimentActive(String experimentName) {
    return _featureFlagService.isEnabled('experiment_$experimentName');
  }
}
