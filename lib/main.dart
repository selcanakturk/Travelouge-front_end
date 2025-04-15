import 'package:flutter/material.dart';
import 'package:travelouge_frontend/app_theme.dart';
import 'package:travelouge_frontend/features/auth/screens/sign_in_screen.dart';
import 'package:travelouge_frontend/features/auth/screens/sign_up_screen.dart';
import 'package:travelouge_frontend/features/auth/screens/welcome_screen.dart';
import 'package:travelouge_frontend/features/home/screens/home_page.dart';
import 'package:travelouge_frontend/features/profile/screens/account_screen.dart';
import 'package:travelouge_frontend/features/route/screens/add_route_screen.dart';
import 'package:travelouge_frontend/features/route/screens/trips_screen.dart';

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
      theme: AppTheme.darkTheme,
      home: const WelcomeScreen(),
      routes: {
        '/login': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/home': (context) => HomePage(),
        '/welcome': (context) => WelcomeScreen(),
        '/trips': (context) => TripsScreen(),
        '/add-route': (context) => AddRouteScreen(),
        '/account': (context) => AccountPage(),
      },
    );
  }
}
