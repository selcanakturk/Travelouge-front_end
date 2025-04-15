import 'package:flutter/material.dart';
import 'package:travelouge_frontend/features/home/screens/home_page.dart';
import 'package:travelouge_frontend/features/home/screens/search_screen.dart';
import 'package:travelouge_frontend/features/route/screens/trips_screen.dart';
import 'package:travelouge_frontend/features/profile/screens/account_screen.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({super.key, required this.currentIndex});

  void _onNavItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return; // zaten aktifse işlem yapma

    if (index == 0) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomePage()));
    } else if (index == 1) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const SearchPage()));
    } else if (index == 2) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const TripsScreen()));
    } else if (index == 3) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const AccountPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      onTap: (index) => _onNavItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Arayın'),
        BottomNavigationBarItem(
            icon: Icon(Icons.favorite), label: 'Seyahatler'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hesap'),
      ],
    );
  }
}
