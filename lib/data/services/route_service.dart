import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travelouge_frontend/core/constants/config.dart'; // ✅ merkezi URL

class RouteService {
  final dio = Dio();

  Future<bool> addRoute(
    String title,
    String description,
    List<XFile> images,
    List<Map<String, double>> routeCoords,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token == null) {
      print("⚠️ Token bulunamadı, giriş yapmalısınız!");
      return false;
    }

    FormData formData = FormData.fromMap({
      "title": title.isEmpty ? 'Untitled' : title,
      "description": description,
      "coordinates": jsonEncode(routeCoords),
      "images": await Future.wait(images.map((image) async {
        return await MultipartFile.fromFile(image.path, filename: image.name);
      }).toList()),
    });

    try {
      final response = await dio.post(
        "${Config.baseUrl}/routes/",
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      return response.statusCode == 201;
    } catch (e) {
      print("❌ Rota ekleme hatası: $e");
      return false;
    }
  }

  Future<bool> updateRoute(
    int routeId,
    String title,
    String description,
    List<XFile> images,
    List<Map<String, double>> routeCoords,
    List<int> deletedImageIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token == null) {
      print("⚠️ Token bulunamadı, giriş yapmalısınız!");
      return false;
    }

    FormData formData = FormData.fromMap({
      "title": title.isEmpty ? 'Untitled' : title,
      "description": description,
      "coordinates": jsonEncode(routeCoords),
      "deleted_image_ids": jsonEncode(deletedImageIds),
      if (images.isNotEmpty)
        "images": await Future.wait(images.map((image) async {
          return await MultipartFile.fromFile(image.path, filename: image.name);
        }).toList()),
    });

    try {
      final response = await dio.patch(
        "${Config.baseUrl}/routes/$routeId/",
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      print("📥 Güncelleme sonucu: ${response.statusCode} - ${response.data}");
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Rota güncelleme hatası: $e");
      return false;
    }
  }

  Future<List<dynamic>> getMyRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) return [];

    try {
      final response = await dio.get(
        "${Config.baseUrl}/routes/",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      return response.statusCode == 200 ? response.data : [];
    } catch (e) {
      print("❌ Rotalar alınamadı: $e");
      return [];
    }
  }

  Future<bool> deleteRoute(int routeId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) return false;

    try {
      final response = await dio.delete(
        "${Config.baseUrl}/routes/$routeId/",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      return response.statusCode == 204;
    } catch (e) {
      print("❌ Silme hatası: $e");
      return false;
    }
  }
}
