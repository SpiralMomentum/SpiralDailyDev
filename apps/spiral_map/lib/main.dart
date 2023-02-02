import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(SpiralDeliveryMapApp());
}

class SpiralDeliveryMapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DeliveryMap',
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
  static const LatLng _kMapCenter =
  LatLng(19.018255973653343, 72.84793849278007);

  static const CameraPosition _kInitialPosition =
  CameraPosition(target: _kMapCenter, zoom: 11.0, tilt: 0, bearing: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps Demo'),
      ),
      body: GoogleMap(
        initialCameraPosition: _kInitialPosition,
      ),
    );
  }
}
