import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travelouge_frontend/core/constants/config.dart';
import 'package:travelouge_frontend/features/profile/screens/edit_profile_page.dart';
import 'package:travelouge_frontend/widget/custom_bottom_nav.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String username = "";
  String email = "";
  String firstName = "";
  String lastName = "";
  String bio = "";
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchAndUpdateUserProfile();
  }

  Future<void> _fetchAndUpdateUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final dio = Dio();

    try {
      final response = await dio.get(
        "${Config.baseUrl}/profile/",
        options: Options(headers: {
          "Authorization": "Bearer $token",
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        await prefs.setString("first_name", data["first_name"] ?? "");
        await prefs.setString("last_name", data["last_name"] ?? "");
        await prefs.setString("username", data["username"] ?? "");
        await prefs.setString("email", data["email"] ?? "");
        await prefs.setString("bio", data["bio"] ?? "");

        if (data["profile_picture"] != null &&
            data["profile_picture"].toString().isNotEmpty) {
          final imageUrl = data["profile_picture"].toString().startsWith("http")
              ? data["profile_picture"]
              : "${Config.baseUrl}${data["profile_picture"]}";
          await prefs.setString("profile_picture", imageUrl);
        } else {
          await prefs.remove("profile_picture");
        }

        setState(() {
          _loadUserInfo();
        });
      }
    } catch (e) {
      print("Kullanıcı profili çekilemedi: $e");
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString("username") ?? "";
      email = prefs.getString("email") ?? "";
      firstName = prefs.getString("first_name") ?? "";
      lastName = prefs.getString("last_name") ?? "";
      bio = prefs.getString("bio") ?? "";
      profileImageUrl = prefs.getString("profile_picture");
    });
  }

  Future<void> logOut(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("access_token");
    prefs.remove("user_id");
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    print(" profileImageUrl from SharedPreferences: $profileImageUrl");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      imageCache.clear();
      imageCache.clearLiveImages();
    });
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        title: const Text(
          "My Account",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
      body: Stack(children: [
        Positioned.fill(
          child: Image.asset(
            'assets/png/header2.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.black.withOpacity(0.85),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.deepPurple,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child: profileImageUrl != null &&
                              profileImageUrl!.startsWith("http")
                          ? Image.network(
                              "${profileImageUrl!}?v=${DateTime.now().millisecondsSinceEpoch}",
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              headers: {
                                'Cache-Control':
                                    'no-cache, no-store, must-revalidate',
                                'Pragma': 'no-cache',
                                'Expires': '0',
                              },
                            )
                          : Image.asset(
                              "assets/png/default_profile.png",
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildGlassCard(children: [
                  _infoRow(Icons.person, "Name", "$firstName $lastName"),
                  const SizedBox(height: 12),
                  _infoRow(Icons.account_circle, "Username", username),
                  const SizedBox(height: 12),
                  _infoRow(Icons.email, "Email", email),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _infoRow(Icons.info_outline, "Bio", bio),
                  ]
                ]),
                const SizedBox(height: 75),
                outlinedGlassButton(
                  label: "Edit Profile",
                  icon: Icons.edit,
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfilePage()),
                    );
                    if (result == true) await _loadUserInfo();
                  },
                ),
                const SizedBox(height: 12),
                outlinedGlassButton(
                  label: "Log Out",
                  icon: Icons.logout,
                  onPressed: () => logOut(context),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required List<Widget> children}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget outlinedGlassButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF251E37), width: 4),
          backgroundColor: Colors.deepPurple.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
