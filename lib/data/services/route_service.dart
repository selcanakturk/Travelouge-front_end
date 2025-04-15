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
}
