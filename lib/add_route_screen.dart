import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:travelouge_frontend/services/route_service.dart';

class AddRouteScreen extends StatefulWidget {
  @override
  _AddRouteScreenState createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<XFile> _images = [];
  final RouteService _routeService =
      RouteService(); // Service sınıfını burada çağır

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
    if (_titleController.text.isEmpty || _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Lütfen başlık girin ve en az bir fotoğraf ekleyin")),
      );
      return;
    }

    bool success = await _routeService.addRoute(
      _titleController.text,
      _descriptionController.text,
      _images,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Rota başarıyla eklendi")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Rota eklenirken hata oluştu")),
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
