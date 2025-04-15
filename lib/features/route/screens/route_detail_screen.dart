import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RouteDetailPage extends StatefulWidget {
  final Map<String, dynamic> route;

  const RouteDetailPage({super.key, required this.route});

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  List<String> imageUrls = [];
  List<LatLng> coordinates = [];
  int currentIndex = 0;
  final String defaultImage = 'assets/png/default.png';
  final String baseUrl = 'http://127.0.0.1:8000';

  @override
  void initState() {
    super.initState();
    final List<dynamic>? images = widget.route["images"];
    if (images != null && images.isNotEmpty) {
      imageUrls = images
          .map<String>((img) =>
              img["image"] != null ? "$baseUrl${img["image"]}" : defaultImage)
          .toList();
    } else {
      imageUrls = [defaultImage];
    }

    final List<dynamic>? coords = widget.route["coordinates"];
    if (coords != null && coords.isNotEmpty) {
      coordinates =
          coords.map((c) => LatLng(c["latitude"], c["longitude"])).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;

    return Scaffold(
      appBar: AppBar(
        title: Text(route["title"] ?? "Route Detail"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 240,
            child: PageView.builder(
              itemCount: imageUrls.length,
              onPageChanged: (index) => setState(() => currentIndex = index),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Image.asset(defaultImage, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              imageUrls.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: currentIndex == index ? 12 : 8,
                height: currentIndex == index ? 12 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      currentIndex == index ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildGlassCard([
            Text(route["title"] ?? "No Title",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(route["description"] ?? "No description"),
            const SizedBox(height: 8),
            Text(
                "📅 ${route["date"]?.toString().substring(0, 10) ?? "No date"}"),
          ]),
          const SizedBox(height: 24),
          if (coordinates.isNotEmpty)
            _buildGlassCard([
              SizedBox(
                height: 250,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: coordinates.first,
                    initialZoom: 13,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(
                      markers: coordinates
                          .map((point) => Marker(
                                point: point,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 30,
                                ),
                              ))
                          .toList(),
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: coordinates,
                          strokeWidth: 4.0,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ]),
        ],
      ),
    );
  }

  Widget _buildGlassCard(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}
