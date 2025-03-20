import 'dart:convert';
//import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = "http://127.0.0.1:8000/api";

  Future<bool> signUp(String username, String email, String password,
      String firstName, String lastName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        body: {
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        },
      );
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 201) {
        return true;
      } else {
        print("Registration failed: ${response.body}");
        return false;
      }
    } catch (e) {
      // Hata durumunu yakala
      print("Error during registration: $e");
      return false;
    }
  }

  Future<bool> signIn(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      body: {
        'username': username,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String token = data['token'];

      // Token'ı kaydet
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      return true;
    } else {
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
