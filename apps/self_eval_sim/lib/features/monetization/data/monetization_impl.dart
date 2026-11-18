import 'dart:io';

import 'package:utils/utils.dart';

import '../domain/monetization.dart';

/// DNS 조회 성공 여부로 온라인을 판단한다.
class DnsConnectivityRepository implements ConnectivityRepository {
  const DnsConnectivityRepository({
    this.host = 'dns.google',
    this.timeout = const Duration(seconds: 2),
  });

  final String host;
  final Duration timeout;

  @override
  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup(host).timeout(timeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

/// 광고 SDK 연동 전까지 쓰는 시뮬레이션 광고. 실제 화면 표시는 앱 조립 영역이 넣어 준다.
class SimulatedRewardedAdRepository implements RewardedAdRepository {
  const SimulatedRewardedAdRepository(this._present);

  /// 광고 화면을 띄우고, 끝까지 봤으면 true.
  final Future<bool?> Function() _present;

  @override
  Future<Result<bool>> showRewarded() => guardAsync(
        action: () async => await _present() ?? false,
        onError: (e, st) => NetworkFailure(message: 'ad', cause: e, stackTrace: st),
      );
}
