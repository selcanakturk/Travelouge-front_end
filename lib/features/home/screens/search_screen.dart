import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travelouge_frontend/core/constants/config.dart';
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
  List<Map<String, dynamic>> recentRoutes = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadRecentRoutes();
  }

  Future<String?> _getUsernameFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access_token");
    if (token == null) return null;

    final parts = token.split('.');
    if (parts.length != 3) return null;

    final payload = parts[1];
    final normalized = base64.normalize(payload);
    final decoded = utf8.decode(base64.decode(normalized));
    final data = json.decode(decoded);
    return data['username'];
  }

  Future<void> _logSearchTerm(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access_token");

    if (token == null || term.isEmpty) return;

    try {
      await Dio().post(
        '${Config.baseUrl}/routes/search-log/',
        data: {'term': term},
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );
    } catch (e) {
      print("Arama terimi loglanamadı: $e");
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _logSearchTerm(query);
      fetchRoutes(query);
    } else {
      setState(() {
        filteredRoutes = [];
      });
    }
  }

  void _clearRecentRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final username = await _getUsernameFromToken();
    if (username == null) return;
    await prefs.remove('recent_routes_$username');
    setState(() {
      recentRoutes.clear();
    });
  }

  Future<void> fetchRoutes(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access_token");

      final dio = Dio();
      dio.options.headers["Authorization"] = "Bearer $token";

      final response = await dio.get('${Config.baseUrl}/routes/all/');
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
      print("Arama sırasında hata: $e");
    }
  }

  Future<void> _saveToRecent(Map<String, dynamic> route) async {
    print("Save to recent triggered");
    final prefs = await SharedPreferences.getInstance();
    final username = await _getUsernameFromToken();
    print("Aktif kullanıcı: $username");
    if (username == null) return;

    String rawImage = '';
    if (route['images'] != null &&
        route['images'].isNotEmpty &&
        route['images'][0]['image'] != null) {
      rawImage = route['images'][0]['image'].toString();
      if (!rawImage.startsWith('http')) {
        rawImage =
            '${Config.baseUrl}${rawImage.startsWith('/') ? '' : '/'}$rawImage';
      }
    }

    final customRoute = {
      'id': route['id'].toString(),
      'title': route['title'] ?? '',
      'description': route['description'] ?? '',
      'image': rawImage,
    };

    setState(() {
      recentRoutes.removeWhere((r) => r['id'] == customRoute['id']);
      recentRoutes.insert(0, {
        ...customRoute,
        'images': [
          {'image': rawImage}
        ]
      });
      if (recentRoutes.length > 8) {
        recentRoutes = recentRoutes.sublist(0, 8);
      }
    });

    final encodedList = recentRoutes.map((r) {
      return Uri(queryParameters: {
        'id': r['id'].toString(),
        'title': r['title'] ?? '',
        'description': r['description'] ?? '',
        'image': r['images']?[0]?['image'] ?? '',
      }).query;
    }).toList();

    await prefs.setStringList('recent_routes_$username', encodedList);
  }

  void _loadRecentRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final username = await _getUsernameFromToken();
    if (username == null) return;

    final recentData = prefs.getStringList('recent_routes_$username') ?? [];

    setState(() {
      recentRoutes = recentData.map((item) {
        final map = Map<String, dynamic>.from(Uri.splitQueryString(item));
        map['images'] = [
          {'image': map['image'] ?? ''}
        ];
        return map;
      }).toList();
    });
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
        title: const Text("Search"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/png/header2.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.85),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _onSearchChanged(),
                  decoration: InputDecoration(
                    hintText: 'Search by route title...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _searchController.text.trim().isEmpty
                      ? _buildRecentRoutesList()
                      : _buildSearchResultsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList() {
    return ListView.builder(
      key: const ValueKey("results"),
      itemCount: filteredRoutes.length,
      itemBuilder: (context, index) {
        final route = filteredRoutes[index];
        return _buildRouteCard(route, saveToRecent: true);
      },
    );
  }

  Widget _buildRecentRoutesList() {
    if (recentRoutes.isEmpty) {
      return const Center(
        child: Text(
          "No recently viewed routes.",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Searches",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: _clearRecentRoutes,
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: "Clear all",
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            key: const ValueKey("recentList"),
            itemCount: recentRoutes.length,
            itemBuilder: (context, index) {
              final route = recentRoutes[index];
              return _buildRouteCard(route);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route,
      {bool saveToRecent = false}) {
    final imageUrl = (route['images'] != null &&
            route['images'].isNotEmpty &&
            route['images'][0]['image'] != null)
        ? (route['images'][0]['image'].toString().startsWith("http")
            ? route['images'][0]['image']
            : '${Config.baseUrl}${route['images'][0]['image']}')
        : 'assets/png/default.png';

    return GestureDetector(
      onTap: () async {
        if (saveToRecent) await _saveToRecent(route);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RouteDetailPage(route: route),
          ),
        );
      },
      child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/png/default.png',
                    width: 90,
                    height: 90,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route['title'] ?? "Untitled",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      route['description'] ?? "No description",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}
