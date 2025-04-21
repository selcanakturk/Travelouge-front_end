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

      if (response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
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

    final dio = Dio();
    dio.options.headers = {
      'Authorization': 'Bearer $token',
    };

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
        "$baseUrl/routes/$routeId/",
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      print("📥 Update response: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 200) {
        print("✅ Rota başarıyla güncellendi.");
        return true;
      } else {
        print(
            "❌ Güncelleme başarısız: ${response.statusCode} - ${response.data}");
        return false;
      }
    } catch (e) {
      print("⚠️ Güncelleme hatası: $e");
      return false;
    }
  }

  Future<List<dynamic>> getMyRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
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

      if (response.statusCode == 200) {
        return response.data;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> deleteRoute(int routeId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
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
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
