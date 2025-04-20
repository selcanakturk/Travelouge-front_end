import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class RouteService {
  final String baseUrl = "http://127.0.0.1:8000/api";

  Future<bool> addRoute(String title, String description, List<XFile> images,
      List<Map<String, double>> routeCoords) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token == null) {
      print("⚠️ Token bulunamadı, giriş yapmalısınız!");
      return false;
    }

    final dio = Dio();
    dio.options.headers = {
      'Authorization': 'Bearer $token',
    };

    // 📌 Verileri logla
    print("📤 Gönderilecek Başlık: $title");
    print("📤 Gönderilecek Açıklama: $description");
    print(
        "📤 Gönderilecek Resimler: ${images.map((image) => image.path).toList()}");
    print("📤 Gönderilecek Koordinatlar: $routeCoords");

    FormData formData = FormData.fromMap({
      "title": title.isEmpty ? 'Untitled' : title,
      "description": description,
      "coordinates": jsonEncode(routeCoords),
      "images": await Future.wait(images.map((image) async {
        return await MultipartFile.fromFile(image.path, filename: image.name);
      }).toList()),
    });

    try {
      Response response = await dio.post(
        "$baseUrl/routes/",
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      print("📥 API Yanıtı: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 201) {
        print("✅ Rota başarıyla eklendi!");
        return true;
      } else {
        print("❌ Rota ekleme başarısız: ${response.data}");
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        print(
            "❌ DioException Hata: ${e.response?.statusCode} - ${e.response?.data}");
      } else {
        print("❌ Genel Hata: $e");
      }
      return false;
    }
  }

  Future<List<dynamic>> getMyRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      print("❌ Token bulunamadı, giriş yapmalısınız.");
      return [];
    }

    final dio = Dio();
    try {
      final response = await dio.get(
        "$baseUrl/routes/",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      print("📥 Kullanıcının rotaları: ${response.data}");

      if (response.statusCode == 200) {
        return response.data;
      } else {
        print("❌ Rota çekme başarısız: ${response.data}");
        return [];
      }
    } catch (e) {
      print("⚠️ Rota çekilirken hata: $e");
      return [];
    }
  }

  Future<bool> deleteRoute(int routeId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      print("❌ Token bulunamadı.");
      return false;
    }

    final dio = Dio();

    try {
      final response = await dio.delete(
        "$baseUrl/routes/$routeId/",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      if (response.statusCode == 204) {
        print("✅ Rota başarıyla silindi!");
        return true;
      } else {
        print("❌ Silme başarısız: ${response.statusCode} - ${response.data}");
        return false;
      }
    } catch (e) {
      print("⚠️ Silme hatası: $e");
      return false;
    }
  }
}
