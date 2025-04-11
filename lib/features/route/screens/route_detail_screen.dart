import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RouteDetailPage extends StatefulWidget {
  final Map<String, dynamic> route;

  const RouteDetailPage({super.key, required this.route});

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  List<String> imageUrls = [];
  final String defaultImage = 'assets/png/default.jpg';
  final String baseUrl = 'http://127.0.0.1:8000';
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    final List<dynamic>? images = widget.route["images"];
    if (images != null && images.isNotEmpty) {
      imageUrls = images
          .map<String>((img) =>
              img["image"] != null ? "$baseUrl${img["image"]}" : defaultImage)
          .toList();
    } else {
      imageUrls = [defaultImage];
    }
  }

  String formatDate(dynamic rawDate) {
    try {
      if (rawDate == null || rawDate.toString().isEmpty) return "Tarih yok";

      final dateTime = DateTime.parse(rawDate.toString());
      final formatter = DateFormat('d MMMM y', 'en_US'); // Örnek: 22 Mart 2025
      return formatter.format(dateTime);
    } catch (e) {
      return "Tarih yok";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.route["title"] ?? "Rota Detayı"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Hero(
            tag: widget.route["image"] + widget.route["title"],
            child: Image.network(
              imageUrls[currentIndex],
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Image.asset(defaultImage, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              imageUrls.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: currentIndex == index ? 12 : 8,
                height: currentIndex == index ? 12 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentIndex == index
                      ? Colors.black
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFDFBFF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${widget.route["title"] ?? "Başlık yok"}"',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${widget.route["description"] ?? "Açıklama yok"}"',
                      style: const TextStyle(
                          fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_pin,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 6),
                        Text(widget.route["location"] ?? "Bilinmeyen Konum",
                            style: const TextStyle(color: Colors.blueGrey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month,
                            color: Colors.grey, size: 20),
                        const SizedBox(width: 6),
                        Text(formatDate(widget.route["date"] ?? ""),
                            style: const TextStyle(color: Colors.blueGrey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
