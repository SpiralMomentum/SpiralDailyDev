import 'package:flutter/material.dart';
import 'package:map_provider_core/map_provider_core.dart';

import 'providers/google_map_provider.dart';
import 'providers/template_placeholder_provider.dart';

void main() {
  runApp(const SpiralDeliveryMapApp());
}

class SpiralDeliveryMapApp extends StatelessWidget {
  const SpiralDeliveryMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spiral Delivery Map',
      home: SpiralDeliveryMap(),
    );
  }
}

class SpiralDeliveryMap extends StatefulWidget {
  const SpiralDeliveryMap({super.key});

  @override
  State<StatefulWidget> createState() => _SpiralDeliveryMapState();
}

class _SpiralDeliveryMapState extends State<SpiralDeliveryMap> {
  late final MapProviderRegistry _registry;
  late String _selectedProviderId;

  MapMarker? _lastTappedMarker;
  GeoCoordinate? _lastTappedCoordinate;
  MapCameraPosition? _lastCameraPosition;

  MapViewConfiguration get _configuration {
    return MapViewConfiguration(
      initialCameraPosition: const MapCameraPosition(
        target: GeoCoordinate(19.018255973653343, 72.84793849278007),
        zoom: 11,
      ),
      markers: {
        MapMarker(
          id: 'spiral-hq',
          position: const GeoCoordinate(19.018255973653343, 72.84793849278007),
          infoWindow: const MapMarkerInfoWindow(
            title: 'Spiral HQ',
            snippet: 'Central Operations Hub',
          ),
          style: const MapMarkerStyle(hue: 210),
          onTap: () => debugPrint('Spiral HQ marker tapped'),
        ),
        MapMarker(
          id: 'delivery-yard',
          position: const GeoCoordinate(19.07283, 72.88261),
          infoWindow: const MapMarkerInfoWindow(
            title: 'Delivery Yard',
            snippet: 'Primary sorting location',
          ),
          style: const MapMarkerStyle(hue: 35),
        ),
      },
      onMarkerTap: (marker) => setState(() => _lastTappedMarker = marker),
      onMapTap: (coordinate) =>
          setState(() => _lastTappedCoordinate = coordinate),
      onCameraMove: (position) => _lastCameraPosition = position,
      onCameraIdle: (position) =>
          setState(() => _lastCameraPosition = position),
    );
  }

  @override
  void initState() {
    super.initState();
    _registry = MapProviderRegistry()
      ..register(GoogleMapProvider())
      ..register(const TemplatePlaceholderProvider());
    final providers = _registry.providers;
    _selectedProviderId =
        providers.isNotEmpty ? providers.first.id : 'template_placeholder';
  }

  @override
  Widget build(BuildContext context) {
    final provider = _registry.resolve(_selectedProviderId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spiral Map Providers'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedProviderId,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _selectedProviderId = value);
                },
                items: _registry.providers
                    .map(
                      (provider) => DropdownMenuItem<String>(
                        value: provider.id,
                        child: Text(provider.displayName),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
      body: provider == null
          ? const Center(child: Text('No map providers registered.'))
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: provider.buildMap(context, _configuration),
                    ),
                  ),
                ),
                _StatusPanel(
                  lastTappedMarker: _lastTappedMarker,
                  lastTappedCoordinate: _lastTappedCoordinate,
                  lastCameraPosition: _lastCameraPosition,
                  selectedProvider: provider.displayName,
                ),
              ],
            ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.lastTappedMarker,
    required this.lastTappedCoordinate,
    required this.lastCameraPosition,
    required this.selectedProvider,
  });

  final MapMarker? lastTappedMarker;
  final GeoCoordinate? lastTappedCoordinate;
  final MapCameraPosition? lastCameraPosition;
  final String selectedProvider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Active provider: $selectedProvider'),
          const SizedBox(height: 8),
          Text(
            lastCameraPosition == null
                ? 'Camera idle at initial position'
                : 'Camera @ '
                    '${lastCameraPosition!.target.latitude.toStringAsFixed(4)}, '
                    '${lastCameraPosition!.target.longitude.toStringAsFixed(4)} '
                    '(zoom: ${lastCameraPosition!.zoom.toStringAsFixed(1)})',
          ),
          const SizedBox(height: 8),
          Text(
            lastTappedCoordinate == null
                ? 'Tap on the map to capture coordinates.'
                : 'Last tap @ '
                    '${lastTappedCoordinate!.latitude.toStringAsFixed(4)}, '
                    '${lastTappedCoordinate!.longitude.toStringAsFixed(4)}',
          ),
          const SizedBox(height: 8),
          Text(
            lastTappedMarker == null
                ? 'Tap a marker to see selection updates.'
                : 'Last marker tapped: ${lastTappedMarker!.id}',
          ),
        ],
      ),
    );
  }
}
