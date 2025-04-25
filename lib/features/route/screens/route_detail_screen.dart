import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as osm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travelouge_frontend/core/constants/config.dart';
import 'package:travelouge_frontend/features/route/screens/add_route_screen.dart';
import 'route_preview_map_screen.dart';
import 'package:travelouge_frontend/widget/custom_snackbar.dart';

class RouteDetailPage extends StatefulWidget {
  final Map<String, dynamic> route;

  const RouteDetailPage({super.key, required this.route});

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  List<String> imageUrls = [];
  List<osm.LatLng> coordinates = [];
  int currentIndex = 0;
  final String defaultImage = 'assets/png/default.png';
  bool isOwner = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final List<dynamic>? images = widget.route["images"];
    if (images != null && images.isNotEmpty) {
      imageUrls = images.map<String>((img) {
        final imgUrl = img["image"] ?? '';
        if (imgUrl.toString().startsWith("http")) {
          return imgUrl;
        } else if (imgUrl.toString().startsWith("/")) {
          return "${Config.baseUrl}$imgUrl";
        } else {
          return "${Config.baseUrl}/$imgUrl";
        }
      }).toList();
    } else {
      imageUrls = [defaultImage];
    }

    final List<dynamic>? coords = widget.route["coordinates"];
    if (coords != null && coords.isNotEmpty) {
      coordinates =
          coords.map((c) => osm.LatLng(c["latitude"], c["longitude"])).toList();
    }

    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt('user_id');
    final routeOwnerId = widget.route["user"] ??
        widget.route["user_id"] ??
        widget.route["owner"] ??
        widget.route["owner_id"];

    if (currentUserId != null && routeOwnerId != null) {
      setState(() {
        isOwner = currentUserId == routeOwnerId;
      });
    }
  }

  void _openFullMapPreview() {
    if (coordinates.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutePreviewMapScreen(
          routePoints: coordinates
              .map((point) => gmap.LatLng(point.latitude, point.longitude))
              .toList(),
          initialCenter: gmap.LatLng(
            coordinates.first.latitude,
            coordinates.first.longitude,
          ),
        ),
      ),
    );
  }

  void _showImagePreview(int initialIndex) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                PageView.builder(
                  controller: PageController(initialPage: initialIndex),
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return Hero(
                      tag: imageUrls[index] + (widget.route["title"] ?? ""),
                      child: InteractiveViewer(
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(defaultImage, fit: BoxFit.contain),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editRoute() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRouteScreen(existingRoute: widget.route),
      ),
    );

    if (mounted) {
      setState(() {
        _loadData();
      });
    }
  }

  void _deleteRoute() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Delete this route?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "This action cannot be undone.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white12,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Cancel",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Delete",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    final routeId = widget.route["id"];
    final url = Uri.parse('${Config.baseUrl}/routes/$routeId/');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        if (context.mounted) {
          showCustomSnackbar(
            context: context,
            message: "Route successfully deleted",
            backgroundColor: Colors.redAccent.withOpacity(0.9),
            icon: Icons.delete_outline,
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception("Delete Error");
      }
    } catch (e) {
      if (context.mounted) {
        showCustomSnackbar(
          context: context,
          message: "Delete Error",
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          icon: Icons.delete_outline,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final rawDate = route["created_at"];
    final String formattedDate =
        rawDate != null ? rawDate.toString().substring(0, 10) : "No date";
    final profilePictureUrl = route["profile_picture"];

    return Scaffold(
      appBar: AppBar(
        title: Text(route["title"] ?? "Route Detail"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          Stack(
            children: [
              SizedBox(
                height: 280,
                child: PageView.builder(
                  itemCount: imageUrls.length,
                  onPageChanged: (index) =>
                      setState(() => currentIndex = index),
                  itemBuilder: (context, index) {
                    return Hero(
                      tag: imageUrls[index] + (route["title"] ?? ""),
                      child: GestureDetector(
                        onTap: () => _showImagePreview(index),
                        child: Image.network(
                          imageUrls[index], //  ZATEN DÜZENLİ GELİYOR
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(defaultImage, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 19,
                            backgroundImage: profilePictureUrl != null
                                ? NetworkImage(profilePictureUrl)
                                : const AssetImage(
                                        "assets/png/default_profile.png")
                                    as ImageProvider,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (route["first_name"] != null &&
                                  route["last_name"] != null)
                                Text(
                                  "${route["first_name"]} ${route["last_name"]}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                              Text(
                                "@${route["username"] ?? "unknown"}",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(route["title"] ?? "",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(route["description"] ?? "",
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              )
            ],
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
                  color: currentIndex == index
                      ? Colors.white
                      : Colors.grey.withOpacity(0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              "\u{1F4C5} $formattedDate",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          if (coordinates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildGlassCard([
                SizedBox(
                  height: 250,
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: coordinates.first,
                          initialZoom: 15,
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
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(onTap: _openFullMapPreview),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          const SizedBox(height: 24),
          if (isOwner)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editRoute,
                      icon:
                          const Icon(Icons.edit, size: 18, color: Colors.white),
                      label: const Text("Edit",
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deleteRoute,
                      icon: const Icon(Icons.delete,
                          size: 18, color: Colors.redAccent),
                      label: const Text("Delete",
                          style:
                              TextStyle(color: Colors.redAccent, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.redAccent.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
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
