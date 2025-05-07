import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:travelouge_frontend/core/constants/config.dart';

class ResetPasswordPage extends StatefulWidget {
  final String uid;
  final String token;

  const ResetPasswordPage({
    super.key,
    required this.uid,
    required this.token,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitNewPassword() async {
    final newPassword = _newPasswordController.text.trim();
    if (newPassword.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await Dio().post(
        '${Config.baseUrl}/users/password-reset-confirm/',
        data: {
          'uid': widget.uid,
          'token': widget.token,
          'new_password': newPassword,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.data['message'] ?? 'Success')),
      );

      // Giriş ekranına yönlendir
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Password reset failed")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Reset Your Password")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Enter your new password.",
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            TextField(
              controller: _newPasswordController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                hintText: "New password",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitNewPassword,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Reset Password"),
            ),
          ],
        ),
      ),
    );
  }
}
