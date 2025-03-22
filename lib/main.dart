import 'package:flutter/material.dart';
import 'package:travelouge_frontend/add_route_screen.dart';
import 'package:travelouge_frontend/home_page.dart';
import 'package:travelouge_frontend/sign_in.dart';
import 'package:travelouge_frontend/sign_up.dart';
import 'package:travelouge_frontend/trips_screen.dart';
import 'package:travelouge_frontend/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Travelouge',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WelcomeScreen(),
      routes: {
        '/login': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/home': (context) => HomePage(),
        '/trips': (context) => TripsScreen(),
        '/add-route': (context) => AddRouteScreen(),
      },
    );
  }
}
