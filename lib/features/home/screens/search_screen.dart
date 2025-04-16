import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:travelouge_frontend/features/route/screens/route_detail_screen.dart';
import 'package:travelouge_frontend/widget/custom_bottom_nav.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Map<String, dynamic>> allRoutes = [];
  List<Map<String, dynamic>> filteredRoutes = [];
  final TextEditingController _searchController = TextEditingController();
  final String baseUrl = 'http://127.0.0.1:8000';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      fetchRoutes(query);
    } else {
      setState(() {
        filteredRoutes = [];
      });
    }
  }

  Future<void> fetchRoutes(String query) async {
    try {
      final response = await Dio().get('$baseUrl/api/routes/all/');
      final all = List<Map<String, dynamic>>.from(response.data);
      final results = all
          .where((route) => route['title']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();

      setState(() {
        allRoutes = all;
        filteredRoutes = results;
      });
    } catch (e) {
      print("❌ Arama sırasında hata: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Arayın", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) => _onSearchChanged(),
              decoration: InputDecoration(
                hintText: 'Rota başlığına göre ara...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(1, 0), // sağdan gelsin
                    end: Offset.zero,
                  ).animate(animation);

                  return SlideTransition(
                      position: offsetAnimation, child: child);
                },
                child: _searchController.text.isEmpty
                    ? const Center(
                        key: ValueKey("empty"),
                        child: Text(
                          "Bir şeyler yazın...",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : filteredRoutes.isEmpty
                        ? const Center(
                            key: ValueKey("notfound"),
                            child: Text(
                              "Sonuç bulunamadı.",
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            key: const ValueKey("results"),
                            itemCount: filteredRoutes.length,
                            itemBuilder: (context, index) {
                              final route = filteredRoutes[index];
                              final imageUrl = (route['images'] != null &&
                                      route['images'].isNotEmpty)
                                  ? '$baseUrl${route['images'][0]['image']}'
                                  : 'assets/png/default.png';

                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RouteDetailPage(route: route),
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          imageUrl,
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Image.asset(
                                                      'assets/png/default.png',
                                                      width: 90,
                                                      height: 90),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              route['title'] ?? "Başlıksız",
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              route['description'] ??
                                                  "Açıklama yok",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white70,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
