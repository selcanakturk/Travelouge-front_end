import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travelouge_frontend/core/constants/config.dart';
import 'package:travelouge_frontend/features/route/screens/add_route_screen.dart';
import 'package:travelouge_frontend/features/route/screens/route_detail_screen.dart';
import 'package:intl/intl.dart';

Dio dio = Dio();

class TripsScreen extends StatefulWidget {
  final int? userId;
  final String? username;
  const TripsScreen({super.key, this.userId, this.username});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  List<Map<String, dynamic>> userRoutes = [];
  final String defaultImage = 'assets/png/default.png';
  String fullName = "";
  String username = "";
  String bio = "";
  String? profilePictureUrl = '';
  bool isOwner = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    await Future.wait([fetchUserProfile(), fetchUserRoutes()]);
  }

  String formatDate(dynamic rawDate) {
    try {
      if (rawDate == null || rawDate.toString().isEmpty) return "Tarih yok";
      final dateTime = DateTime.tryParse(rawDate.toString());
      if (dateTime == null) return "Tarih yok";
      final localDate = dateTime.toLocal();
      final formatter = DateFormat('d MMMM y', 'tr_TR');
      return formatter.format(localDate);
    } catch (e) {
      print("📅 Tarih formatlama hatası: $e");
      return "Tarih yok";
    }
  }

  Future<void> fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    try {
      final response = await dio.get(
        widget.userId != null
            ? '${Config.baseUrl}/users/${widget.userId}/'
            : '${Config.baseUrl}/profile/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final currentUserId = prefs.getInt("user_id");
      setState(() {
        fullName =
            "${response.data['first_name']} ${response.data['last_name']}";
        username = response.data['username'];
        bio = response.data['bio'] ?? "";
        profilePictureUrl = response.data['profile_picture'];
        isOwner = currentUserId == response.data['id'];

        if (profilePictureUrl != null && profilePictureUrl!.isNotEmpty) {
          if (!profilePictureUrl!.startsWith("http")) {
            profilePictureUrl = "${Config.baseUrl}$profilePictureUrl";
          }
        } else {
          profilePictureUrl = null;
        }
      });
    } catch (e) {
      print("❌ Kullanıcı bilgisi alınamadı: $e");
    }
  }

  Future<void> fetchUserRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    try {
      final endpoint = widget.userId != null
          ? '${Config.baseUrl}/routes/all/'
          : '${Config.baseUrl}/routes/';

      final response = await dio.get(
        endpoint,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      List<dynamic> data = response.data;
      List<Map<String, dynamic>> routes = [];

      for (var route in data) {
        if (route["is_deleted"] == true) continue;

        final ownerId = route["user"] ?? route["user_id"] ?? route["owner"];
        if (widget.userId != null && ownerId != widget.userId) continue;

        String imageUrl = defaultImage;
        if (route["images"] != null &&
            route["images"].isNotEmpty &&
            route["images"][0]["image"] != null) {
          final raw = route["images"][0]["image"].toString();
          imageUrl = raw.startsWith("http")
              ? raw
              : raw.startsWith("/")
                  ? "${Config.baseUrl}$raw"
                  : "${Config.baseUrl}/$raw";
        }

        String location =
            await _getLocationFromCoordinates(route["coordinates"]);
        route["image"] = imageUrl;
        route["location"] = location;
        route["date"] = route["created_at"];

        routes.add(route);
      }

      setState(() {
        userRoutes = routes;
      });
    } catch (e) {
      print("❌ Hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Seyahatler", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileSection(),
          Expanded(
            child: userRoutes.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: userRoutes.length,
                    itemBuilder: (context, index) {
                      return _buildRouteCard(userRoutes[index]);
                    },
                  ),
          )
        ],
      ),
      floatingActionButton: isOwner ? _buildFloatingButton() : null,
    );
  }

  Widget _buildProfileSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[800],
            backgroundImage:
                profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                    ? NetworkImage(profilePictureUrl!)
                    : const AssetImage('assets/png/default_profile.png')
                        as ImageProvider,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isNotEmpty ? fullName : "İsim yok",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  username.isNotEmpty ? '@$username' : "@unknown",
                  style: const TextStyle(
                      color: Colors.purpleAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w400),
                ),
                Text(
                  bio.isNotEmpty ? bio : "Açıklama yok",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, right: 12.0),
      child: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRouteScreen()),
          );
          fetchUserRoutes();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Yeni Rota",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.explore, size: 80, color: Colors.white24),
          SizedBox(height: 16),
          Text("Henüz bir rota eklemediniz!",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(height: 8),
          Text("Yeni bir keşif yapmaya ne dersiniz?",
              style: TextStyle(fontSize: 16, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final String imageUrl = route["image"].toString();
    final bool isNetwork = imageUrl.startsWith("http");

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RouteDetailPage(route: route),
          ),
        );

        if (result == true) {
          fetchUserRoutes();
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Hero(
              tag: imageUrl + route["title"],
              child: isNetwork
                  ? Image.network(
                      imageUrl,
                      height: double.infinity,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset(defaultImage, fit: BoxFit.cover),
                    )
                  : Image.asset(
                      defaultImage,
                      height: double.infinity,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route["title"],
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            route["location"],
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.white70, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            formatDate(route["date"]),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

Future<String> _getLocationFromCoordinates(dynamic coords) async {
  try {
    if (coords == null || coords.isEmpty) return "Konum belirtilmedi";
    final lat = coords[0]["latitude"];
    final lng = coords[0]["longitude"];

    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      return place.locality ??
          place.administrativeArea ??
          place.country ??
          "Bilinmeyen Konum";
    } else {
      return "Konum bulunamadı";
    }
  } catch (e) {
    print("📍 Konum çözümleme hatası: $e");
    return "Konum bulunamadı";
  }
}
