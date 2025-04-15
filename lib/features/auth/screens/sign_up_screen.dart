import 'package:flutter/material.dart';
import 'package:travelouge_frontend/data/services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  bool _obscurePassword = true;

  void _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      bool success = await _authService.signUp(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
        _confirmPasswordController.text,
        _firstNameController.text,
        _lastNameController.text,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kayıt başarılı!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kayıt başarısız!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.only(top: 100),
                children: [
                  const Text(
                    "Hesap Oluştur",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField("Ad", _firstNameController,
                      (v) => v!.isEmpty ? "Ad gerekli" : null),
                  const SizedBox(height: 12),
                  _buildTextField("Soyad", _lastNameController,
                      (v) => v!.isEmpty ? "Soyad gerekli" : null),
                  const SizedBox(height: 12),
                  _buildTextField("Kullanıcı Adı", _usernameController,
                      (v) => v!.isEmpty ? "Kullanıcı adı gerekli" : null),
                  const SizedBox(height: 12),
                  _buildTextField("E-posta", _emailController,
                      (v) => v!.isEmpty ? "E-posta gerekli" : null),
                  const SizedBox(height: 12),
                  _buildTextField("Parola", _passwordController,
                      (v) => v!.isEmpty ? "Parola gerekli" : null,
                      isPassword: true),
                  const SizedBox(height: 12),
                  _buildTextField(
                      "Parolayı Doğrula", _confirmPasswordController, (v) {
                    if (v == null || v.isEmpty) {
                      return "Lütfen parolayı tekrar girin";
                    }
                    if (v != _passwordController.text) {
                      return "Parolalar eşleşmiyor";
                    }
                    return null;
                  }, isPassword: true),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        "Kayıt Ol",
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 🔙 Geri Dön Butonu
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/welcome');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    String? Function(String?) validator, {
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: isPassword && _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
      ),
    );
  }
}
