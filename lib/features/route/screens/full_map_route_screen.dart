import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;

class FullMapRouteScreen extends StatefulWidget {
  final List<LatLng> initialPoints;
  final LatLng initialCenter;

  const FullMapRouteScreen({
    super.key,
    this.initialPoints = const [],
    required this.initialCenter,
  });

  @override
  State<FullMapRouteScreen> createState() => _FullMapRouteScreenState();
}

class _FullMapRouteScreenState extends State<FullMapRouteScreen> {
  List<LatLng> routePoints = [];
  bool isMarking = false;
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    routePoints = [...widget.initialPoints];
  }

  void _onTapMap(LatLng latlng) {
    if (!isMarking) return;
    setState(() => routePoints.add(latlng));
  }

  void _toggleMarking() {
    setState(() => isMarking = !isMarking);
  }

  void _clearRoute() {
    setState(() => routePoints.clear());
  }

  void _saveAndReturn() {
    Navigator.pop(context, routePoints);
  }

  Future<void> _searchAndMoveToLocation(String query) async {
    try {
      if (query.trim().isEmpty) return;
      List<geo.Location> locations = await geo.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(location.latitude, location.longitude),
            15.0,
          ),
        );
      } else {
        throw Exception("Boş sonuç.");
      }
    } catch (e) {
      print('📍 Arama hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location not found")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Route Map', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveAndReturn,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: routePoints.isNotEmpty
                  ? routePoints.first
                  : widget.initialCenter,
              zoom: 13,
            ),
            onMapCreated: (controller) => _mapController = controller,
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
                  color: Colors.lightBlueAccent,
                  width: 4,
                ),
            },
            myLocationEnabled: true,
            onTap: _onTapMap,
          ),
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.white.withOpacity(0.7),
                    child: TextField(
                      style: const TextStyle(color: Colors.black),
                      controller: _searchController,
                      onSubmitted: (query) {
                        _searchAndMoveToLocation(query);
                        FocusScope.of(context).unfocus();
                      },
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Colors.black),
                        hintText: "Search location...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.black54),
                      ),
                    )),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildGlassButton(
                  onPressed: _toggleMarking,
                  icon: isMarking ? Icons.close : Icons.edit_location_alt,
                  label: Text(
                    isMarking ? 'Stop Marking' : 'Start Marking',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(height: 12),
                _buildGlassButton(
                  onPressed: _clearRoute,
                  icon: Icons.delete_outline,
                  label: const Text(
                    'Clear Route',
                    style: TextStyle(color: Colors.black),
                  ),
                  color: Colors.redAccent,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

Widget _buildGlassButton({
  required VoidCallback onPressed,
  required IconData icon,
  required Widget label,
  Color color = Colors.white24,
}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child:
                Icon(icon, key: ValueKey(icon), size: 20, color: Colors.white),
          ),
          label: label,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.3),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    ),
  );
}
