import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountPage extends StatelessWidget {
  // Log Out işlemi ve yönlendirme
  Future<void> logOut(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token'); // Token'ı sil
    print("✅ Kullanıcı çıkışı yapıldı");

    // Çıkış yaptıktan sonra Welcome Screen sayfasına yönlendir
    Navigator.pushReplacementNamed(context,
        '/welcome'); // '/welcome' sayfası Welcome Screen'in route ismi olmalı
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Beyaz arka plan
      appBar: AppBar(
        backgroundColor: Colors.black, // Siyah AppBar
        title: Text(
          "Hesap Sayfası",
          style: TextStyle(color: Colors.white), // Beyaz başlık yazısı
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.white),
            onPressed: () {
              // Ana sayfaya dönüş
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0), // Genel padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı Bilgileri Alanı
            Container(
              width: double.infinity, // Ekranın tamamını kaplasın
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100], // Hafif gri arka plan
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kullanıcı Adı",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Kullanıcı Adı Burada",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "E-posta",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "kullanici@ornek.com",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            Spacer(), // İçeriği üstte hizalamak için Spacer ekledik
            // Çıkış Yap Butonu
            Center(
              child: ElevatedButton(
                onPressed: () => logOut(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  backgroundColor: Colors.red, // Kırmızı buton
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Çıkış Yap",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Beyaz metin
                  ),
                ),
              ),
            ),
            SizedBox(height: 100), // Buton ile alt arasına boşluk ekledik
          ],
        ),
      ),
    );
  }
}
