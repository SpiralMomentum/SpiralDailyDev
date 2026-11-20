import 'package:utils/utils.dart';

/// 보상형 광고 제안 규칙 (명세 1절 "수익 모델", "오프라인").
/// - 노출은 누적 발현 시에만.
/// - 오프라인에서는 광고 없이 동작.
abstract final class AdOfferPolicy {
  static bool shouldOffer({required bool manifested, required bool online}) =>
      manifested && online;
}

abstract interface class ConnectivityRepository {
  Future<bool> isOnline();
}

/// 보상형 광고 경계. 끝까지 보면 true(보상), 중간에 닫으면 false.
abstract interface class RewardedAdRepository {
  Future<Result<bool>> showRewarded();
}

class DecideAdOfferUseCase {
  const DecideAdOfferUseCase(this._connectivity);

  final ConnectivityRepository _connectivity;

  Future<bool> call({required bool manifested}) async {
    if (!manifested) return false;
    return AdOfferPolicy.shouldOffer(
      manifested: manifested,
      online: await _connectivity.isOnline(),
    );
  }
}

class ShowRewardedAdUseCase {
  const ShowRewardedAdUseCase(this._ads);

  final RewardedAdRepository _ads;

  Future<Result<bool>> call() => _ads.showRewarded();
}
