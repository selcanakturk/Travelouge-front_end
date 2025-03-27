import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travelouge_frontend/features/route/screens/add_route_screen.dart';
import 'package:travelouge_frontend/features/route/screens/route_detail_screen.dart';

Dio dio = Dio();

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  List<Map<String, String>> userRoutes = [];
  final String defaultImage =
      "https://via.placeholder.com/300x200.png?text=No+Image";

  @override
  void initState() {
    super.initState();
    fetchUserRoutes();
  }

  Future<void> fetchUserRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    try {
      final response = await dio.get(
        'http://127.0.0.1:8000/api/routes/',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      print("✅ Başarıyla çekildi: ${response.data}");

      // Gelen veriyi listeye ekleyelim
      List<dynamic> data = response.data; // JSON array

      setState(() {
        userRoutes = data.map<Map<String, String>>((route) {
          return {
            "title": route["title"]?.toString() ?? "Başlıksız",
            "description": route["description"]?.toString() ?? "Açıklama yok",
            "location": route["location"]?.toString() ?? "Bilinmeyen Konum",
            "date": route["created_at"]?.toString() ?? "Tarih yok",
            "image": (route["images"] != null && route["images"].isNotEmpty)
                ? route["images"][0].toString()
                : defaultImage,
          };
        }).toList();
      });
    } catch (e) {
      print("❌ Hata oluştu: $e");
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: userRoutes.length,
              itemBuilder: (context, index) {
                return _buildRouteCard(userRoutes[index]);
              },
            ),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  Widget _buildFloatingButton() {
    return FloatingActionButton.extended(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddRouteScreen()),
        );
        fetchUserRoutes(); // Yeni rota eklenince listeyi güncelle
      },
      icon: const Icon(Icons.add, size: 28, color: Colors.black),
      label: const Text("Yeni Rota Ekle",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
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

  Widget _buildRouteCard(Map<String, String> route) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              route["image"]!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.network(defaultImage, width: 60, height: 60);
              },
            ),
          ),
        ),
        title: Text(route["title"]!,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (route["description"] != null)
              Text(route["description"]!,
                  style: const TextStyle(color: Colors.grey)),
            Text("📍 ${route["location"]!}",
                style: const TextStyle(color: Colors.blueGrey)),
            Text("📅 ${route["date"]!}",
                style: const TextStyle(color: Colors.blueGrey)),
          ],
        ),
        onTap: () {
          // Rota detay sayfasına yönlendirme
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RouteDetailPage(route: route),
            ),
          );
        },
      ),
    );
  }
}
