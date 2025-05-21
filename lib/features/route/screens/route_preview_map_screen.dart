import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RoutePreviewMapScreen extends StatelessWidget {
  final List<LatLng> routePoints;
  final LatLng initialCenter;

  const RoutePreviewMapScreen({
    super.key,
    required this.routePoints,
    required this.initialCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Route Preview"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: routePoints.isNotEmpty ? routePoints.first : initialCenter,
          zoom: 17,
        ),
        markers: routePoints
            .map((point) => Marker(
                  markerId: MarkerId(point.toString()),
                  position: point,
                ))
            .toSet(),
        polylines: {
          if (routePoints.length >= 2)
            Polyline(
              polylineId: const PolylineId('route'),
              points: routePoints,
              color: Colors.blue,
              width: 4,
            ),
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      ),
    );
  }
}
