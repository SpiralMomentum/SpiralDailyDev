import 'package:flutter/foundation.dart';

import 'map_provider.dart';

/// Simple registry that keeps track of available map providers and the active
/// selection.
class MapProviderRegistry extends ChangeNotifier {
  MapProviderRegistry({
    required List<MapProvider> providers,
    MapProviderType? initialType,
  }) : _providers = {
          for (final provider in providers) provider.type: provider,
        } {
    if (_providers.isEmpty) {
      throw ArgumentError('At least one map provider must be registered.');
    }
    _activeType = initialType ?? providers.first.type;
  }

  final Map<MapProviderType, MapProvider> _providers;
  late MapProviderType _activeType;
  bool _initialized = false;

  MapProvider get activeProvider => _providers[_activeType]!;
  MapProviderType get activeType => _activeType;
  List<MapProvider> get availableProviders =>
      List.unmodifiable(_providers.values);

  Future<void> initializeActive() async {
    if (_initialized) return;
    await activeProvider.initialize();
    _initialized = true;
  }

  Future<void> switchTo(MapProviderType type) async {
    if (type == _activeType) return;
    final provider = _providers[type];
    if (provider == null) {
      throw ArgumentError('Provider $type is not registered.');
    }
    await provider.initialize();
    _activeType = type;
    _initialized = true;
    notifyListeners();
  }

  void register(MapProvider provider) {
    _providers[provider.type] = provider;
    notifyListeners();
  }
}
