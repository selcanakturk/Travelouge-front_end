import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travelouge_frontend/core/constants/config.dart';
import 'package:travelouge_frontend/features/route/screens/route_detail_screen.dart';
import 'package:travelouge_frontend/widget/custom_app_bar.dart';
import 'package:travelouge_frontend/widget/custom_bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> popularRoutes = [];

  @override
  void initState() {
    super.initState();
    fetchPopularRoutes();
  }

  Future<void> fetchPopularRoutes() async {
    try {
      final response = await Dio().get('${Config.baseUrl}/routes/popular/');
      if (response.statusCode == 200) {
        setState(() {
          popularRoutes = List<Map<String, dynamic>>.from(response.data);
        });
      }
    } catch (e) {
      print("❌ Popüler rotalar çekilemedi: $e");
    }
  }

  Future<void> _determinePosition(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum servisleri kapalı.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum izni reddedildi.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum izni kalıcı olarak reddedildi.')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Konum alındı: ${position.latitude}, ${position.longitude}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Where would you like to go?",
        leading: const Icon(Icons.location_on, color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Bildirim butonu aksiyonu
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Arkadaki görsel + blur
          Positioned.fill(
            child: Image.asset(
              'assets/png/header2.jpg', // Kendi görseline göre değiştir
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ),
          // Asıl içerik
          SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Gezilecek yerleri arayın...',
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        filled: true,
        fillColor: Colors.white12,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildLocationSearch(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _determinePosition(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white12,
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.place, color: Colors.white),
          SizedBox(width: 10),
          Text('Konuma göre ara', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPopularRoutesList(List<Map<String, dynamic>> routes) {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RouteDetailPage(route: route),
                ),
              );
            },
            child: buildPopularRouteCard(route),
          );
        },
      ),
    );
  }

  Widget buildPopularRouteCard(Map<String, dynamic> route) {
    final imageUrl = (route['images'] != null &&
            route['images'].isNotEmpty &&
            route['images'][0]['image'] != null)
        ? (route['images'][0]['image'].toString().startsWith("http")
            ? route['images'][0]['image']
            : '${Config.baseUrl}${route['images'][0]['image']}')
        : 'assets/png/default.png';

    final routeTitle = route['title'] ?? "Başlıksız";
    final username = route['username'] ?? "unknown_user";
    final likes = route['likes_count']?.toString() ?? "0";
    final comments = route['comments_count']?.toString() ?? "0";

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: imageUrl.startsWith("http")
              ? NetworkImage(imageUrl)
              : AssetImage(imageUrl) as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.90), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routeTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black38,
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.redAccent, size: 18),
                const SizedBox(width: 6),
                Text(
                  likes,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.comment, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Text(
                  comments,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderList() {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  // Widget _buildAppBar() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
  //     child: Row(
  //       children: [
  //         const Icon(Icons.location_on, color: Colors.white),
  //         const SizedBox(width: 8),
  //         const Expanded(
  //           child: Text(
  //             "Nereye gitmek istiyorsunuz?",
  //             style: TextStyle(fontSize: 22, color: Colors.white),
  //           ),
  //         ),
  //         IconButton(
  //           icon: const Icon(Icons.notifications, color: Colors.white),
  //           onPressed: () {},
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 20),
          _buildLocationSearch(context),
          const SizedBox(height: 20),
          const Text("Popüler Rotalar",
              style: TextStyle(fontSize: 20, color: Colors.white)),
          const SizedBox(height: 10),
          _buildPopularRoutesList(popularRoutes),
          const SizedBox(height: 20),
          const Text("Son incelenenler",
              style: TextStyle(fontSize: 20, color: Colors.white)),
          const SizedBox(height: 10),
          _buildPlaceholderList(),
        ],
      ),
    );
  }
}
