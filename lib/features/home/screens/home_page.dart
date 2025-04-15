import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travelouge_frontend/features/home/screens/search_screen.dart';
import 'package:travelouge_frontend/features/profile/screens/account_screen.dart';
import 'package:travelouge_frontend/features/route/screens/trips_screen.dart';
import 'package:travelouge_frontend/widget/custom_bottom_nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
          content: Text(
              'Konum alındı: ${position.latitude}, ${position.longitude}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const Icon(Icons.location_on, color: Colors.white),
        title: const Text("Nereye gitmek istiyorsunuz?",
            style: TextStyle(fontSize: 22, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
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
              _buildHorizontalList(),
              const SizedBox(height: 20),
              const Text("Son incelenenler",
                  style: TextStyle(fontSize: 20, color: Colors.white)),
              const SizedBox(height: 10),
              _buildHorizontalList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
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

  Widget _buildHorizontalList() {
    return SizedBox(
      height: 350,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Seçilen yer $index')),
              );
            },
            child: Container(
              width: 250,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: const Color(0xFF2C2C2E),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
                image: const DecorationImage(
                  image: NetworkImage('https://source.unsplash.com/random'),
                  fit: BoxFit.cover,
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(12),
              child: const Text(
                'Yer İsmi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
