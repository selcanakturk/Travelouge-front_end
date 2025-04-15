import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = "http://127.0.0.1:8000/api";

  // 🚀 Kayıt olma
  Future<bool> signUp(
    String username,
    String email,
    String password,
    String confirmPassword,
    String firstName,
    String lastName,
  ) async {
    final dio = Dio();

    try {
      final response = await dio.post(
        '$baseUrl/register/',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
          'first_name': firstName,
          'last_name': lastName,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
      );

      print("✅ Kayıt başarılı: ${response.statusCode} - ${response.data}");
      return response.statusCode == 201;
    } on DioException catch (e) {
      print("❌ Kayıt hatası: ${e.response?.data}");
      return false;
    } catch (e) {
      print("⚠️ Genel kayıt hatası: $e");
      return false;
    }
  }

  // 🔐 Giriş işlemi
  Future<bool> signIn(String username, String password) async {
    final dio = Dio();

    try {
      final response = await dio.post(
        "$baseUrl/token/",
        data: {"username": username, "password": password},
      );

      if (response.statusCode == 200) {
        final accessToken = response.data['access'];
        final refreshToken = response.data['refresh'];

        if (accessToken != null && refreshToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
          await prefs.setString('refresh_token', refreshToken);
          await prefs.setString('username', username);

          // 👤 Kullanıcı bilgilerini çek
          await fetchUserProfile();

          print("✅ Giriş başarılı, token ve kullanıcı bilgileri kaydedildi!");
          return true;
        } else {
          print("❌ Token bilgileri eksik.");
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

  // 👤 Kullanıcı bilgilerini çek ve kaydet
  Future<void> fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final dio = Dio();

    try {
      final response = await dio.get(
        "$baseUrl/profile/",
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      final data = response.data;
      await prefs.setString('email', data['email'] ?? '');
      await prefs.setString('first_name', data['first_name'] ?? '');
      await prefs.setString('last_name', data['last_name'] ?? '');

      print("👤 Kullanıcı profil verisi başarıyla kaydedildi");
    } catch (e) {
      print("❌ Kullanıcı profil verisi alınamadı: $e");
    }
  }
}
