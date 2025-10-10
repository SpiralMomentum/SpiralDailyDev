import 'package:flutter/foundation.dart';

import 'map_provider_adapter.dart';

/// Registry used to manage map provider implementations at runtime.
class MapProviderRegistry {
  MapProviderRegistry();

  final Map<String, MapProviderAdapter> _providers = <String, MapProviderAdapter>{};

  /// Registers a provider. When a provider with the same [id] already exists
  /// it will be replaced by the new instance.
  void register(MapProviderAdapter provider) {
    _providers[provider.id] = provider;
  }

  /// Removes a provider by identifier.
  void unregister(String id) {
    _providers.remove(id);
  }

  /// Returns the provider matching the supplied [id] or `null` if none is
  /// registered for that identifier.
  MapProviderAdapter? resolve(String id) => _providers[id];

  /// All registered providers sorted by their display names for a stable UI.
  List<MapProviderAdapter> get providers {
    final items = _providers.values.toList(growable: false);
    items.sort((a, b) => compareAsciiLowerCase(a.displayName, b.displayName));
    return items;
  }

  /// True when at least one provider has been registered.
  bool get hasProviders => _providers.isNotEmpty;
}
