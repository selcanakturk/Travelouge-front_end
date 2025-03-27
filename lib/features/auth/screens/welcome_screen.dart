import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travelouge_frontend/features/auth/screens/sign_in_screen.dart';
import 'package:travelouge_frontend/features/auth/screens/sign_up_screen.dart';

//import 'home_page.dart'; // HomePage'i dahil ediyoruz

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus(); // Uygulama başlar başlamaz giriş durumu kontrol edilir
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token != null) {
      print("🔓 Kullanıcı giriş yapmış, token geçerli: $token");
      Navigator.pushReplacementNamed(context, '/home'); // Ana sayfaya yönlendir
    } else {
      print("🔐 Kullanıcı giriş yapmamış.");
      // Kullanıcı giriş yapmamışsa, mevcut WelcomeScreen gösterilmeye devam eder
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/png/login_screen.png', // Arka plan resmi
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withAlpha(128), // %50 opacity
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "TRAVELOUGE",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Explore your journeys",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Share your routes with the world!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                _buildButton(context, "SIGN UP", const SignUpPage()),
                const SizedBox(height: 10),
                _buildButton(context, "SIGN IN", const SignInPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, Widget page) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => page));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
