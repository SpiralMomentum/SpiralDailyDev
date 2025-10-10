import 'package:app_navigation/app_navigation.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';
import 'package:utils/utils.dart';

class ProviderCatalogPage extends StatelessWidget {
  const ProviderCatalogPage({
    super.key,
    required this.registry,
    required this.routesController,
    required this.markerCustomizer,
  });

  final MapProviderRegistry registry;
  final RoutesController routesController;
  final MapMarkerCustomizer markerCustomizer;

  @override
  Widget build(BuildContext context) {
    final providers = registry.availableProviders;
    return Scaffold(
      appBar: AppBar(
        title: const Text('지도 제공자 카탈로그'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '활성화된 마커 커스터마이저: ${markerCustomizer.runtimeType}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  final provider = providers[index];
                  final hint = provider is TemplateMapProvider
                      ? provider.integrationHint
                      : '이 제공자에 맞게 초기화를 구성하세요.';
                  return MapProviderPreview(
                    title: provider.displayName,
                    description: hint,
                    accentColor: _accentColor(provider.type, Theme.of(context)),
                    onTap: () async {
                      await registry.switchTo(provider.type);
                      if (context.mounted) {
                        routesController.pop(context);
                      }
                    },
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemCount: providers.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accentColor(MapProviderType type, ThemeData theme) {
    switch (type) {
      case MapProviderType.openStreetMap:
        return Colors.orange;
      case MapProviderType.google:
        return Colors.indigo;
      case MapProviderType.naver:
        return Colors.green;
      case MapProviderType.amazon:
        return theme.colorScheme.secondary;
    }
  }
}
