import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/monetization/data/monetization_impl.dart';
import 'package:self_eval_sim/features/monetization/domain/monetization.dart';
import 'package:utils/utils.dart';

class _Connectivity implements ConnectivityRepository {
  _Connectivity(this.online);

  final bool online;
  int calls = 0;

  @override
  Future<bool> isOnline() async {
    calls++;
    return online;
  }
}

void main() {
  group('AdOfferPolicy', () {
    test('발현 + 온라인일 때만 제안한다', () {
      expect(AdOfferPolicy.shouldOffer(manifested: true, online: true), isTrue);
      expect(AdOfferPolicy.shouldOffer(manifested: true, online: false), isFalse);
      expect(AdOfferPolicy.shouldOffer(manifested: false, online: true), isFalse);
      expect(AdOfferPolicy.shouldOffer(manifested: false, online: false), isFalse);
    });
  });

  group('DecideAdOfferUseCase', () {
    test('발현이 없으면 연결 확인조차 하지 않는다', () async {
      final c = _Connectivity(true);
      expect(await DecideAdOfferUseCase(c)(manifested: false), isFalse);
      expect(c.calls, 0);
    });

    test('발현 시 연결 상태를 따른다', () async {
      expect(await DecideAdOfferUseCase(_Connectivity(true))(manifested: true), isTrue);
      expect(await DecideAdOfferUseCase(_Connectivity(false))(manifested: true), isFalse);
    });
  });

  group('SimulatedRewardedAdRepository', () {
    test('끝까지 보면 true, 닫으면(null 포함) false, 예외는 Failure', () async {
      expect((await SimulatedRewardedAdRepository(() async => true).showRewarded()).dataOrNull, isTrue);
      expect((await SimulatedRewardedAdRepository(() async => null).showRewarded()).dataOrNull, isFalse);
      final failed = await SimulatedRewardedAdRepository(() async => throw StateError('x')).showRewarded();
      expect(failed.failureOrNull, isA<NetworkFailure>());
      expect((await ShowRewardedAdUseCase(SimulatedRewardedAdRepository(() async => true))()).dataOrNull, isTrue);
    });
  });

  test('DnsConnectivityRepository: 존재하지 않는 호스트는 오프라인', () async {
    const repo = DnsConnectivityRepository(host: 'nonexistent.invalid', timeout: Duration(seconds: 2));
    expect(await repo.isOnline(), isFalse);
  });
}
