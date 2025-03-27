import 'package:flutter/material.dart';

class RouteDetailPage extends StatelessWidget {
  final Map<String, String> route;

  RouteDetailPage({required this.route});

  @override
  Widget build(BuildContext context) {
    var imageUrl = route["image"] ??
        "https://via.placeholder.com/300x200.png?text=No+Image";

    return Scaffold(
      appBar: AppBar(
        title: Text(route["title"]!),
        backgroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Geri dönme işlemi
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Image.network(imageUrl,
                width: double.infinity, height: 250, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                route["title"]!,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                route["description"]!,
                style: TextStyle(fontSize: 16),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "📍 ${route["location"]!}",
                style: TextStyle(color: Colors.blueGrey, fontSize: 16),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "📅 ${route["date"]!}",
                style: TextStyle(color: Colors.blueGrey, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
