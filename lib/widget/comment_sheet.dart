import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travelouge_frontend/core/constants/config.dart';

class CommentsSheet extends StatefulWidget {
  final int routeId;
  final int routeOwnerId;

  const CommentsSheet(
      {super.key, required this.routeId, required this.routeOwnerId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  List<dynamic> comments = [];
  final TextEditingController _commentController = TextEditingController();
  bool isLoading = true;
  int currentUserId = -1;
  late int routeOwnerId;
  int commentsCount = 0;
  @override
  void initState() {
    super.initState();
    routeOwnerId = widget.routeOwnerId;
    _loadUserData();
    _fetchComments();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt('user_id') ?? -1;
    });
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/routes/${widget.routeId}/comments/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({"text": text}),
      );

      if (response.statusCode == 201) {
        _commentController.clear();
        Navigator.pop(context, true); // Yorum başarılı eklendiyse kapat
      } else {
        print('Yorum eklenemedi: ${response.body}');
        print('Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Yorum eklenirken hata: $e');
    }
  }

  Future<void> _fetchComments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/routes/${widget.routeId}/comments/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedComments = json.decode(response.body);
        setState(() {
          comments = fetchedComments;
          commentsCount =
              fetchedComments.length; // YORUM SAYISI BURADA GÜNCELLENİR
          isLoading = false;
        });
      } else {
        print('Yorumlar çekilemedi: ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Yorumlar çekilirken hata: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
            const Text('Delete Comment', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this comment?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    try {
      final response = await http.delete(
        Uri.parse(
            '${Config.baseUrl}/routes/${widget.routeId}/comments/$commentId/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        setState(() {
          comments.removeWhere((comment) => comment['id'] == commentId);
          commentsCount = (commentsCount - 1)
              .clamp(0, double.infinity)
              .toInt(); // 🔥 yorum sayısını azalt
        });
        Navigator.pop(context, true);
      } else {
        print('Yorum silinemedi: ${response.body}');
      }
    } catch (e) {
      print('Yorum silinirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const Text(
                'Comments',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  comment['profile_picture'] != null
                                      ? NetworkImage(comment['profile_picture'])
                                      : const AssetImage(
                                              'assets/png/default_profile.png')
                                          as ImageProvider,
                            ),
                            title: Text(
                              comment['username'] ?? 'Unknown',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              comment['text'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16), // yazı fontu büyütüldü
                            ),
                            trailing: (comment['user_id'] == currentUserId ||
                                    routeOwnerId == currentUserId)
                                ? IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.redAccent),
                                    onPressed: () =>
                                        _deleteComment(comment['id']),
                                  )
                                : null,
                          );
                        },
                      ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _addComment,
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
