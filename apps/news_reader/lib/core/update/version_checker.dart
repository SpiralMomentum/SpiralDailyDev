import 'package:apps.news_reader/core/services/remote_config_service.dart';

enum UpdateRequirement { none, soft, forced }

class VersionChecker {
  const VersionChecker(this._remoteConfig);

  final RemoteConfigService _remoteConfig;

  static const String currentVersion = '1.0.0';

  UpdateRequirement check() {
    final minVersion =
        _remoteConfig.getString('min_version', defaultValue: '1.0.0');
    final latestVersion =
        _remoteConfig.getString('latest_version', defaultValue: '1.0.0');

    if (_isLessThan(currentVersion, minVersion)) {
      return UpdateRequirement.forced;
    }
    if (_isLessThan(currentVersion, latestVersion)) {
      return UpdateRequirement.soft;
    }
    return UpdateRequirement.none;
  }

  static bool _isLessThan(String a, String b) {
    final partsA = a.split('.').map(int.parse).toList();
    final partsB = b.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      final va = i < partsA.length ? partsA[i] : 0;
      final vb = i < partsB.length ? partsB[i] : 0;
      if (va < vb) return true;
      if (va > vb) return false;
    }
    return false;
  }
}
