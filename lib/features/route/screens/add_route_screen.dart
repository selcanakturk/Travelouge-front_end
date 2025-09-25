import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travelouge_frontend/core/constants/config.dart';
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
  final List<XFile> _images = [];
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
                  "url": img['image'].toString().startsWith('http')
                      ? img['image']
                      : "${Config.baseUrl}${img['image']}"
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
    final List<XFile> pickedFiles = await picker.pickMultiImage();
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
                isEditMode ? " Route updated" : " Route added successfully")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save route")),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Enter route title",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text("Description", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Describe your journey...",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
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
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white70),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      IgnorePointer(
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
                          gestureRecognizers:
                              <Factory<OneSequenceGestureRecognizer>>{}.toSet(),
                        ),
                      ),
                      Positioned.fill(
                        child: Material(
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
            const SizedBox(height: 24),
            Text("Photos", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: pickImages,
              icon: const Icon(Icons.photo, color: Colors.white),
              label: const Text(
                "Select Photos",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: TextButton.styleFrom(
                side: const BorderSide(color: Color(0xFF251E37), width: 5),
                backgroundColor: Colors.deepPurple.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            if (_networkImages.isNotEmpty || _images.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _networkImages.length + _images.length,
                itemBuilder: (context, index) {
                  bool isNetwork = index < _networkImages.length;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: isNetwork
                            ? Image.network(
                                _networkImages[index]['url'],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image, size: 50),
                              )
                            : Image.file(
                                File(_images[index - _networkImages.length]
                                    .path),
                                width: double.infinity,
                                height: double.infinity,
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
                            onPressed: () => _removeImage(
                              isNetwork ? index : index - _networkImages.length,
                              isNetwork: isNetwork,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            else
              const Text("No photos selected yet."),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: submitRoute,
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(
                  isEditMode ? "Save" : "Add Route",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF251E37), width: 5),
                  backgroundColor: Colors.deepPurple.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
