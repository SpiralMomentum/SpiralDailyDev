abstract class RemoteConfigService {
  Future<void> fetchAndActivate();
  String getString(String key, {String defaultValue = ''});
  int getInt(String key, {int defaultValue = 0});
  bool getBool(String key, {bool defaultValue = false});
}

class MockRemoteConfigService implements RemoteConfigService {
  MockRemoteConfigService({Map<String, dynamic>? overrides})
      : _values = {..._defaults, ...?overrides};

  final Map<String, dynamic> _values;

  static const Map<String, dynamic> _defaults = {
    'min_version': '1.0.0',
    'latest_version': '1.0.0',
    'force_update_enabled': false,
  };

  @override
  Future<void> fetchAndActivate() async {}

  @override
  String getString(String key, {String defaultValue = ''}) =>
      _values[key] as String? ?? defaultValue;

  @override
  int getInt(String key, {int defaultValue = 0}) =>
      _values[key] as int? ?? defaultValue;

  @override
  bool getBool(String key, {bool defaultValue = false}) =>
      _values[key] as bool? ?? defaultValue;
}
