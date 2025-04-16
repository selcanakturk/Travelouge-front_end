import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travelouge_frontend/data/services/route_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:travelouge_frontend/features/route/screens/full_map_route_screen.dart';

class AddRouteScreen extends StatefulWidget {
  @override
  _AddRouteScreenState createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<XFile> _images = [];
  final RouteService _routeService = RouteService();

  List<LatLng> _routePoints = [];
  LatLng? _currentLocation;
  GoogleMapController? _miniMapController;

  final LatLng _fallbackCenter = const LatLng(41.0082, 28.9784);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  Future<void> pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _images = pickedFiles;
      });
    }
  }

  Future<void> submitRoute() async {
    if (_titleController.text.isEmpty || _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Please enter a title and select at least one photo.")),
      );
      return;
    }

    List<Map<String, double>> routeCoords = _routePoints
        .map((point) =>
            {"latitude": point.latitude, "longitude": point.longitude})
        .toList();

    bool success = await _routeService.addRoute(
      _titleController.text,
      _descriptionController.text,
      _images,
      routeCoords,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Route added successfully")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to add route")),
      );
    }
  }

  void _openFullMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullMapRouteScreen(
          initialPoints: _routePoints,
          initialCenter: _currentLocation ?? _fallbackCenter,
        ),
      ),
    );

    if (result != null && result is List<LatLng>) {
      setState(() {
        _routePoints = result;

        // mini harita kontrolcüsü varsa kamerayı güncelle
        if (_miniMapController != null && _routePoints.isNotEmpty) {
          _miniMapController!.animateCamera(
            CameraUpdate.newLatLngBounds(
              _boundsFromLatLngList(_routePoints),
              50,
            ),
          );
        }
      });
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double x0 = list.first.latitude;
    double x1 = list.first.latitude;
    double y0 = list.first.longitude;
    double y1 = list.first.longitude;

    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(x0, y0),
      northeast: LatLng(x1, y1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = _routePoints.isNotEmpty
        ? _routePoints.first
        : (_currentLocation ?? _fallbackCenter);

    return Scaffold(
      appBar: AppBar(title: const Text("Add New Route")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _openFullMap,
                child: Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: center,
                            zoom: 13,
                          ),
                          onMapCreated: (controller) {
                            _miniMapController = controller;
                            if (_routePoints.isNotEmpty) {
                              controller.animateCamera(
                                CameraUpdate.newLatLngBounds(
                                  _boundsFromLatLngList(_routePoints),
                                  50,
                                ),
                              );
                            }
                          },
                          markers: _routePoints
                              .map((point) => Marker(
                                    markerId: MarkerId(point.toString()),
                                    position: point,
                                  ))
                              .toSet(),
                          polylines: {
                            if (_routePoints.length >= 2)
                              Polyline(
                                polylineId: const PolylineId('route'),
                                color: Colors.blue,
                                width: 4,
                                points: _routePoints,
                              ),
                          },
                          myLocationEnabled: true,
                          zoomControlsEnabled: false,
                          onTap: (_) {},
                          gestureRecognizers:
                              <Factory<OneSequenceGestureRecognizer>>{}.toSet(),
                        ),
                        Positioned.fill(
                          child: Container(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _openFullMap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: pickImages,
                child: const Text("📷 Select Photos"),
              ),
              const SizedBox(height: 10),
              _images.isNotEmpty
                  ? Wrap(
                      spacing: 8,
                      children: _images
                          .map((image) => Image.file(
                                File(image.path),
                                width: 100,
                                height: 100,
                              ))
                          .toList(),
                    )
                  : const Text("No photos selected yet."),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitRoute,
                child: const Text("✅ Add Route"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
