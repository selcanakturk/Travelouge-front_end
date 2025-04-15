import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travelouge_frontend/data/services/route_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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
  MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _locationPermissionGranted = false;

  final LatLng _fallbackCenter = LatLng(41.0082, 28.9784); // Istanbul fallback

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
        _locationPermissionGranted = true;
      });
    } else {
      setState(() {
        _locationPermissionGranted = false;
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
        SnackBar(
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
        SnackBar(content: Text("✅ Route added successfully")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to add route")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = _currentLocation ?? _fallbackCenter;

    return Scaffold(
      appBar: AppBar(title: Text("Add New Route")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 20),
              Container(
                height: 250,
                margin: EdgeInsets.only(bottom: 16),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 13,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _routePoints.add(point);
                        print("📍 Added: $point");
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    if (_locationPermissionGranted && _currentLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.green,
                              size: 30,
                            ),
                          ),
                          ..._routePoints.map(
                            (point) => Marker(
                              point: point,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 4.0,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: pickImages,
                child: Text("📷 Select Photos"),
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
                  : Text("No photos selected yet."),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitRoute,
                child: Text("✅ Add Route"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
