import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as osm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travelouge_frontend/core/constants/config.dart';
import 'package:travelouge_frontend/features/route/screens/add_route_screen.dart';
import 'package:travelouge_frontend/features/route/screens/trips_screen.dart';
import 'package:travelouge_frontend/widget/comment_sheet.dart';
import 'package:travelouge_frontend/widget/custom_app_bar.dart';
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
  bool isLiked = false;
  bool isSaved = false;
  bool isSavedChanged = false;
  bool isExpanded = false;
  int likesCount = 0;
  int commentsCount = 0;
  int currentIndex = 0;
  final String defaultImage = 'assets/png/default.png';
  bool isOwner = false;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await _refreshRouteData(); // önce veriyi çek
    await checkIfLiked(); // beğeni kontrolü
    await checkIfSaved(); // kaydetme kontrolü
    await _loadData(); // state güncelle
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
        likesCount = widget.route['likes_count'] ?? 0;
        commentsCount = widget.route['comments_count'] ?? 0;
        isLiked = widget.route['is_liked_by_current_user'] ?? false;
      });
    }
    print(coordinates);
    //  Like bilgilerini çek
    setState(() {
      likesCount = widget.route['likes_count'] ?? 0;
      commentsCount = widget.route['comments_count'] ?? 0;
    });
  }

  Future<void> _refreshRouteData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final routeId = widget.route["id"];

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/routes/$routeId/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> updatedData =
            json.decode(utf8.decode(response.bodyBytes));

        setState(() {
          widget.route.clear();
          widget.route.addAll(updatedData);
          _loadData();
        });
      }
    } catch (e) {
      print("Rota verisi yenilenemedi: $e");
    }
  }

  void _navigateToUserTrips() {
    final routeOwnerId = widget.route["user"] ??
        widget.route["user_id"] ??
        widget.route["owner"] ??
        widget.route["owner_id"];

    if (routeOwnerId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripsScreen(userId: routeOwnerId),
        ),
      );
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
                    onPressed: () => Navigator.pop(context, true),
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRouteScreen(existingRoute: widget.route),
      ),
    );

    if (result == true && mounted) {
      _refreshRouteData();
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
      appBar: CustomAppBar(
        title: "View Route",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, isSavedChanged); // değişiklik bildirimi
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          Stack(
            children: [
              SizedBox(
                height: 280,
                child: PageView.builder(
                  controller: PageController(),
                  itemCount: imageUrls.length,
                  onPageChanged: (index) =>
                      setState(() => currentIndex = index),
                  itemBuilder: (context, index) {
                    return Hero(
                      tag: imageUrls[index] + (route["title"] ?? ""),
                      child: GestureDetector(
                        onTap: () => _showImagePreview(index),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(defaultImage, fit: BoxFit.cover),
                            ),
                            // GRADIENT OVERLAY
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 12),
              Positioned(
                bottom: 2,
                left: 2,
                right: 2,
                child: GestureDetector(
                  onTap: _navigateToUserTrips,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
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
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
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
                        Text(
                          route["description"] ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                          maxLines: isExpanded ? null : 1,
                          overflow: isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                        if ((route["description"] ?? "").toString().length >
                            100)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isExpanded = !isExpanded;
                              });
                            },
                            child: Text(
                              isExpanded ? "Show less" : "Read more",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
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
          if (coordinates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 250,
                      child: FlutterMap(
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
                    ),

                    // Ripple effect
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openFullMapPreview,
                          splashColor: Colors.white.withOpacity(0.1),
                          highlightColor: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),

                    // Optional: label on map
                    Positioned(
                      bottom: 8,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Tap to open map',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => toggleLike(widget.route['id']),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.white,
                            size: 25,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$likesCount',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _openComments,
                      child: Row(
                        children: [
                          const Icon(Icons.mode_comment_outlined,
                              color: Colors.white, size: 25),
                          const SizedBox(width: 4),
                          Text(
                            '$commentsCount',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => toggleSave(widget.route['id']),
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? Colors.white : Colors.white,
                        size: 25,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_month,
                        color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
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

  Future<void> toggleLike(int routeId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = Uri.parse('${Config.baseUrl}/routes/$routeId/like/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final liked = data['liked'];

        setState(() {
          isLiked = liked;
          if (liked) {
            likesCount += 1;
          } else {
            likesCount = (likesCount - 1).clamp(0, double.infinity).toInt();
          }
        });
      } else {
        print('Like/Unlike başarısız: ${response.body}');
      }
    } catch (e) {
      print('Like/Unlike Hatası: $e');
    }
  }

  Future<void> checkIfLiked() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    print("🔥 checkIfLiked(): token = $token");

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/routes/${widget.route['id']}/is-liked/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          isLiked = data['is_liked'] ?? false;
        });
      } else {
        print('Beğeni durumu kontrol edilemedi: ${response.body}');
      }
    } catch (e) {
      print('Beğeni durumu çekilirken hata: $e');
    }
  }

  Future<void> checkIfSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/routes/${widget.route['id']}/is-saved/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          isSaved = data['is_saved'] ?? false;
        });
      } else {
        print('Kaydedilme durumu kontrol edilemedi: ${response.body}');
      }
    } catch (e) {
      print('Kaydedilme durumu çekilirken hata: $e');
    }
  }

  Future<void> toggleSave(int routeId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = Uri.parse('${Config.baseUrl}/routes/$routeId/save/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final saved = data['saved'];

        setState(() {
          isSaved = saved;
          isSavedChanged = true;
        });
      } else {
        print('Kaydetme işlemi başarısız: ${response.body}');
      }
    } catch (e) {
      print('Kaydetme hatası: $e');
    }
  }

  void _openComments() async {
    final routeId = widget.route['id'];
    final routeOwnerId = widget.route['user'] ??
        widget.route['user_id'] ??
        widget.route['owner'];

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CommentsSheet(
          routeId: routeId,
          routeOwnerId: routeOwnerId,
          onCommentAdded: () {
            setState(() {
              commentsCount++; // anlık arttır
            });
          },
        );
      },
    );

    if (result == true) {
      _refreshRouteData(); // silme işlemi sonrası güncelleme
    }
  }
}
