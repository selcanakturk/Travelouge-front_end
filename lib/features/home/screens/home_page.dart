import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travelouge_frontend/core/constants/config.dart';
import 'package:travelouge_frontend/features/route/screens/route_detail_screen.dart';
import 'package:travelouge_frontend/widget/custom_bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> popularRoutes = [];
  List<Map<String, dynamic>> suggestedRoutes = [];
  List<Map<String, dynamic>> savedRoutes = [];

  @override
  void initState() {
    super.initState();
    fetchPopularRoutes();
    fetchSuggestedRoutes();
    fetchSavedRoutes();
  }

  Future<void> fetchPopularRoutes() async {
    try {
      final response = await Dio().get('${Config.baseUrl}/routes/popular/');
      if (response.statusCode == 200) {
        setState(() {
          popularRoutes = List<Map<String, dynamic>>.from(response.data);
        });
      }
    } catch (e) {
      print("Failed to fetch popular routes: $e");
    }
  }

  Future<void> fetchSuggestedRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access_token");

      final dio = Dio();
      dio.options.headers["Authorization"] = "Bearer $token";

      final response = await dio.get(
        '${Config.baseUrl}/routes/suggested/?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      if (response.statusCode == 200) {
        setState(() {
          suggestedRoutes = List<Map<String, dynamic>>.from(response.data);
        });
      }
    } catch (e) {
      print("Failed to fetch suggested routes: $e");
    }
  }

  Future<void> fetchSavedRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access_token");

      final dio = Dio();
      dio.options.headers["Authorization"] = "Bearer $token";

      final response = await dio.get('${Config.baseUrl}/routes/saved/');
      if (response.statusCode == 200) {
        setState(() {
          savedRoutes = List<Map<String, dynamic>>.from(response.data);
        });
      }
    } catch (e) {
      print("Failed to fetch saved routes: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/search');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: const [
            Icon(Icons.search, color: Colors.white70),
            SizedBox(width: 10),
            Text(
              "Search for places to explore...",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularRoutesList(List<Map<String, dynamic>> routes) {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];
          return GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RouteDetailPage(route: route),
                ),
              );

              if (result == true) {
                await fetchSavedRoutes();
                setState(() {});
              }
            },
            child: buildPopularRouteCard(route),
          );
        },
      ),
    );
  }

  Widget buildPopularRouteCard(Map<String, dynamic> route) {
    final imageUrl = (route['images'] != null &&
            route['images'].isNotEmpty &&
            route['images'][0]['image'] != null)
        ? (route['images'][0]['image'].toString().startsWith("http")
            ? route['images'][0]['image']
            : '${Config.baseUrl}${route['images'][0]['image']}')
        : 'assets/png/default.png';

    final routeTitle = route['title'] ?? "Untitled";
    final username = route['username'] ?? "unknown_user";
    final likes = route['likes_count']?.toString() ?? "0";
    final comments = route['comments_count']?.toString() ?? "0";

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: imageUrl.startsWith("http")
              ? NetworkImage(imageUrl)
              : AssetImage(imageUrl) as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.90), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routeTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black38,
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.redAccent, size: 18),
                const SizedBox(width: 6),
                Text(
                  likes,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.comment, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Text(
                  comments,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedRoutesList(List<Map<String, dynamic>> routes) {
    if (routes.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Explore",
                style: TextStyle(fontSize: 20, color: Colors.white)),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: "Refresh",
              onPressed: () async {
                await fetchSuggestedRoutes();
              },
            )
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteDetailPage(route: route),
                    ),
                  );

                  if (result == true) {
                    await fetchSavedRoutes();
                    setState(() {});
                  }
                },
                child: buildPopularRouteCard(route),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Where would you like to go?",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 30),
          _buildSearchBar(),
          const SizedBox(height: 30),
          const Text("Popular Routes",
              style: TextStyle(fontSize: 20, color: Colors.white)),
          const SizedBox(height: 20),
          _buildPopularRoutesList(popularRoutes),
          const SizedBox(height: 20),
          _buildSuggestedRoutesList(suggestedRoutes),
          const SizedBox(height: 30),
          _buildSavedRoutesSection(savedRoutes),
        ],
      ),
    );
  }

  Widget _buildSavedRoutesSection(List<Map<String, dynamic>> routes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Saved Routes",
            style: TextStyle(fontSize: 20, color: Colors.white)),
        const SizedBox(height: 10),
        if (routes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Center(
              child: Text(
                "You haven't saved any routes yet.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          )
        else
          SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RouteDetailPage(route: route),
                      ),
                    );

                    if (result == true) {
                      await fetchSavedRoutes();
                      setState(() {});
                    }
                  },
                  child: buildPopularRouteCard(route),
                );
              },
            ),
          ),
      ],
    );
  }
}
