import 'package:flutter/material.dart';

import 'map_marker.dart';
import 'map_provider_adapter.dart';
import 'map_view_configuration.dart';

/// Template that can be extended by teams implementing a new provider.
///
/// The default implementation renders a placeholder widget to highlight where
/// the actual map should appear. Extending classes are expected to override
/// [buildPlaceholder] or [buildMap] to hook in their own provider specific
/// widgets.
abstract class MapProviderTemplate extends MapProviderAdapter {
  const MapProviderTemplate();

  @override
  Widget buildMap(BuildContext context, MapViewConfiguration configuration) {
    return buildPlaceholder(context, configuration);
  }

  /// Override this method to render provider specific widgets.
  @protected
  Widget buildPlaceholder(
    BuildContext context,
    MapViewConfiguration configuration,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined,
                  color: Theme.of(context).colorScheme.primary, size: 48),
              const SizedBox(height: 16),
              Text(
                'Implement the $displayName provider by overriding buildMap.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool supportsMarkerStyle(MapMarkerStyle style) => true;
}
