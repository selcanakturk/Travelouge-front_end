import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travelouge_frontend/features/route/screens/add_route_screen.dart';
import 'package:travelouge_frontend/features/route/screens/route_detail_screen.dart';
import 'package:intl/intl.dart';

Dio dio = Dio();

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  List<Map<String, dynamic>> userRoutes = [];
  final String defaultImage = 'assets/png/default.jpg';
  @override
  void initState() {
    super.initState();
    fetchUserRoutes();
  }

  String formatDate(dynamic rawDate) {
    try {
      if (rawDate == null || rawDate.toString().isEmpty) return "Tarih yok";

      final dateTime = DateTime.parse(rawDate.toString());
      final formatter = DateFormat('d MMMM y', 'tr_TR'); // Örnek: 22 Mart 2025
      return formatter.format(dateTime);
    } catch (e) {
      return "Tarih yok";
    }
  }

  Future<void> fetchUserRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    const baseUrl = 'http://127.0.0.1:8000';

    try {
      final response = await dio.get(
        '$baseUrl/api/routes/',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      print("🧪 Backend verisi: ${response.data}");

      List<dynamic> data = response.data;

      setState(() {
        userRoutes = data.map<Map<String, dynamic>>((route) {
          String imageUrl = defaultImage;

          if (route["images"] != null &&
              route["images"].isNotEmpty &&
              route["images"][0]["image"] != null) {
            imageUrl = "$baseUrl${route["images"][0]["image"]}";
          }

          return {
            "title": route["title"]?.toString() ?? "Başlıksız",
            "description": route["description"]?.toString() ?? "Açıklama yok",
            "location": route["location"]?.toString() ?? "Bilinmeyen Konum",
            "date": route["created_at"] ?? "",
            "image": imageUrl,
            "images": route["images"] ?? [], // 🔥 asıl veri bu
          };
        }).toList();
      });
    } catch (e) {
      print("❌ Hata oluştu: \$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Seyahatlerim", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context, '/home', (route) => false),
        ),
      ),
      body: userRoutes.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 sütun
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8, // Kart yüksekliğini ayarlar
              ),
              itemCount: userRoutes.length,
              itemBuilder: (context, index) {
                return _buildRouteCard(userRoutes[index]);
              },
            ),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  Widget _buildFloatingButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, right: 12.0),
      child: Align(
        alignment: Alignment.bottomRight,
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
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black,
          elevation: 10,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text("Henüz bir rota eklemediniz!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Yeni bir keşif yapmaya ne dersiniz?",
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final String imageUrl = route["image"].toString();
    final bool isNetwork = imageUrl.startsWith("http");

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RouteDetailPage(route: route),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Hero(
              tag: imageUrl + route["title"], // ✅ her kart için benzersiz yap
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
