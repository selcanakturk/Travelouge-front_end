import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class AddRouteScreen extends StatefulWidget {
  @override
  _AddRouteScreenState createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<XFile> _images = [];

  Future<void> pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _images = pickedFiles;
      });
    }
  }

  Future<void> submitRoute() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    print("🛠️ Kaydedilen Token: $token"); // Token'ı terminalde gör

    if (token == null) {
      print("⚠️ Token bulunamadı, giriş yapmalısınız!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lütfen giriş yapın!")),
      );
      return;
    }

    final dio = Dio();
    dio.options.headers["Authorization"] = "Bearer $token";

    if (_titleController.text.isEmpty || _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Lütfen başlık girin ve en az bir fotoğraf ekleyin")),
      );
      return;
    }

    FormData formData = FormData.fromMap({
      "title": _titleController.text,
      "description": _descriptionController.text,
      "images": await Future.wait(_images.map((image) async {
        return await MultipartFile.fromFile(image.path, filename: image.name);
      }).toList()),
    });

    try {
      Response response = await dio.post(
        "http://127.0.0.1:8000/api/routes/",
        data: formData,
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Rota başarıyla eklendi")),
        );
        Navigator.pop(context);
      } else {
        print("❌ Hata: ${response.statusCode} - ${response.data}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("❌ Rota eklenirken hata oluştu: ${response.data}")),
        );
      }
    } catch (e) {
      print("⚠️ Hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Bağlantı hatası, tekrar deneyin!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Yeni Rota Ekle")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Başlık")),
            TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: "Açıklama")),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: pickImages,
              child: Text("📷 Fotoğrafları Seç"),
            ),
            SizedBox(height: 10),
            _images.isNotEmpty
                ? Wrap(
                    spacing: 8,
                    children: _images
                        .map((image) => Image.file(File(image.path),
                            width: 100, height: 100))
                        .toList(),
                  )
                : Text("Henüz fotoğraf seçilmedi"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitRoute,
              child: Text("✅ Rota Ekle"),
            ),
          ],
        ),
      ),
    );
  }
}
