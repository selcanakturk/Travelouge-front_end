import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:travelouge_frontend/core/constants/config.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isLoading = false;
  File? _profileImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _firstNameController.text = prefs.getString("first_name") ?? "";
    _lastNameController.text = prefs.getString("last_name") ?? "";
    _usernameController.text = prefs.getString("username") ?? "";
    _emailController.text = prefs.getString("email") ?? "";
    _bioController.text = prefs.getString("bio") ?? "";
    _profileImageUrl = prefs.getString("profile_picture");
    setState(() {});
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final dio = Dio();

    final formMap = <String, dynamic>{
      "first_name": _firstNameController.text,
      "last_name": _lastNameController.text,
      "username": _usernameController.text,
      "email": _emailController.text,
      "bio": _bioController.text,
    };

    if (_profileImage != null) {
      formMap["profile_picture"] = await MultipartFile.fromFile(
        _profileImage!.path,
        filename: _profileImage!.path.split('/').last,
      );
    }

    final formData = FormData.fromMap(formMap);
    try {
      final response = await dio.patch(
        // 👈 PATCH burada!
        "${Config.baseUrl}/profile/",
        data: formData,
        options: Options(headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "multipart/form-data", // 👈 Bu önemli!
        }),
      );

      print("✅ SERVER RESPONSE: ${response.data}");

      if (response.statusCode == 200) {
        // PATCH başarılı, şimdi GET ile en güncel datayı alalım
        final profileResponse = await dio.get(
          "${Config.baseUrl}/profile/",
          options: Options(headers: {
            "Authorization": "Bearer $token",
          }),
        );

        final profile = profileResponse.data;
        await prefs.setString("first_name", profile["first_name"] ?? "");
        await prefs.setString("last_name", profile["last_name"] ?? "");
        await prefs.setString("username", profile["username"] ?? "");
        await prefs.setString("email", profile["email"] ?? "");
        await prefs.setString("bio", profile["bio"] ?? "");

        if (profile["profile_picture"] != null &&
            profile["profile_picture"].toString().isNotEmpty) {
          final imageUrl =
              profile["profile_picture"].toString().startsWith("http")
                  ? profile["profile_picture"]
                  : "${Config.baseUrl}${profile["profile_picture"]}";
          await prefs.setString("profile_picture", imageUrl);
          setState(() {
            _profileImage = null;
            _profileImageUrl = imageUrl;
          });
        } else {
          await prefs.remove("profile_picture");
          setState(() {
            _profileImage = null;
            _profileImageUrl = null;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profil başarıyla güncellendi.")),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception("Güncelleme hatası");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil güncellenemedi.")),
      );
      print("❌ HATA: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Profili Düzenle",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (_profileImageUrl != null &&
                                _profileImageUrl!.startsWith("http"))
                            ? NetworkImage(_profileImageUrl!)
                            : const AssetImage("assets/png/default_profile.png")
                                as ImageProvider,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField("Ad", _firstNameController),
                const SizedBox(height: 16),
                _buildTextField("Soyad", _lastNameController),
                const SizedBox(height: 16),
                _buildTextField("Kullanıcı Adı", _usernameController),
                const SizedBox(height: 16),
                _buildTextField("E-posta", _emailController),
                const SizedBox(height: 16),
                _buildTextField("Açıklama", _bioController,
                    maxLines: 5, maxLength: 180),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Kaydet",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            )),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/change-password');
                  },
                  icon: const Icon(Icons.lock_outline, color: Colors.white),
                  label: const Text(
                    "Şifreyi Değiştir",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, int? maxLength}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      maxLength: maxLength,
      validator: (value) =>
          value == null || value.isEmpty ? "Bu alan zorunludur" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
