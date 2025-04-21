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
  final Map<String, dynamic>? existingRoute;

  const AddRouteScreen({super.key, this.existingRoute});

  @override
  _AddRouteScreenState createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<XFile> _images = [];
  List<Map<String, dynamic>> _networkImages = [];
  List<int> deletedImageIds = [];
  final RouteService _routeService = RouteService();

  List<LatLng> _routePoints = [];
  LatLng? _currentLocation;
  GoogleMapController? _miniMapController;

  final LatLng _fallbackCenter = const LatLng(41.0082, 28.9784);

  bool get isEditMode => widget.existingRoute != null;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    if (isEditMode) {
      final route = widget.existingRoute!;
      _titleController.text = route['title'] ?? '';
      _descriptionController.text = route['description'] ?? '';
      if (route['coordinates'] != null) {
        _routePoints = List.from(route['coordinates'])
            .map((c) => LatLng(c['latitude'], c['longitude']))
            .toList();
      }
      if (route['images'] != null) {
        _networkImages = List.from(route['images'])
            .map((img) => {
                  "id": img['id'],
                  "url": "http://127.0.0.1:8000${img['image']}"
                })
            .toList();
      }
    }
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
        _images.addAll(pickedFiles);
      });
    }
  }

  void _removeImage(int index, {bool isNetwork = false}) {
    setState(() {
      if (isNetwork) {
        deletedImageIds.add(_networkImages[index]['id']);
        _networkImages.removeAt(index);
      } else {
        _images.removeAt(index);
      }
    });
  }

  Future<void> submitRoute() async {
    if (_titleController.text.isEmpty ||
        (_images.isEmpty && _networkImages.isEmpty && !isEditMode)) {
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

    bool success;
    if (isEditMode) {
      success = await _routeService.updateRoute(
        widget.existingRoute!["id"],
        _titleController.text,
        _descriptionController.text,
        _images,
        routeCoords,
        deletedImageIds,
      );
    } else {
      success = await _routeService.addRoute(
        _titleController.text,
        _descriptionController.text,
        _images,
        routeCoords,
      );
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                isEditMode ? "✅ Route updated" : "✅ Route added successfully")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to save route")),
      );
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

    return LatLngBounds(southwest: LatLng(x0, y0), northeast: LatLng(x1, y1));
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

  @override
  Widget build(BuildContext context) {
    final LatLng center = _routePoints.isNotEmpty
        ? _routePoints.first
        : (_currentLocation ?? _fallbackCenter);

    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? "Edit Route" : "Add New Route")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Route Title", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "Enter route title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text("Description", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Describe your journey...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text("Route Map", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _openFullMap,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: center, zoom: 13),
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
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text("Photos", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: pickImages,
              icon: const Icon(Icons.photo, color: Colors.purple),
              label: const Text(
                "Select Photos",
                style: TextStyle(
                  color: Colors.purple,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _networkImages.isNotEmpty || _images.isNotEmpty
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._networkImages.asMap().entries.map((entry) {
                        int index = entry.key;
                        String url = entry.value['url'];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                url,
                                width: 160,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.close,
                                      size: 18, color: Colors.white),
                                  onPressed: () =>
                                      _removeImage(index, isNetwork: true),
                                ),
                              ),
                            )
                          ],
                        );
                      }),
                      ..._images.asMap().entries.map((entry) {
                        int index = entry.key;
                        XFile image = entry.value;
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(image.path),
                                width: 160,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.close,
                                      size: 18, color: Colors.white),
                                  onPressed: () => _removeImage(index),
                                ),
                              ),
                            )
                          ],
                        );
                      })
                    ],
                  )
                : const Text("No photos selected yet."),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: submitRoute,
                icon: const Icon(Icons.check),
                label: Text(isEditMode ? "Save" : "Add Route"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
