import 'package:flutter/material.dart';
import 'package:map_provider_core/map_provider_core.dart';

/// Example provider built on top of [MapProviderTemplate].
class TemplatePlaceholderProvider extends MapProviderTemplate {
  const TemplatePlaceholderProvider();

  @override
  String get id => 'template_placeholder';

  @override
  String get displayName => 'Custom Provider Template';

  @override
  Widget buildPlaceholder(
    BuildContext context,
    MapViewConfiguration configuration,
  ) {
    return super.buildPlaceholder(context, configuration);
  }
}
