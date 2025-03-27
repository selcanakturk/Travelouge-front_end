//import 'dart:convert';
//import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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
    try {
      final dio = Dio();
      final response = await dio.post(
        "http://127.0.0.1:8000/api/token/",
        data: {"username": username, "password": password},
      );

      if (response.statusCode == 200) {
        final accessToken = response.data['access'];
        final refreshToken = response.data['refresh'];

        if (accessToken != null && refreshToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
          await prefs.setString('refresh_token', refreshToken);

          print("✅ Giriş başarılı, token kaydedildi!");
          print("Access Token: $accessToken");
          print("Refresh Token: $refreshToken");

          return true; // Başarılı giriş
        } else {
          print("❌ Erişim token'ları alınamadı.");
          return false;
        }
      } else {
        print("❌ Giriş başarısız: ${response.data}");
        return false;
      }
    } catch (e) {
      print("⚠️ Giriş hatası: $e");
      return false;
    }
  }
}
