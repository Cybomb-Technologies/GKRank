import 'package:flutter/material.dart';
import '../../../core/data_repository.dart';
import '../../home/presentation/user_level_questions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarksListScreen extends StatefulWidget {
  const BookmarksListScreen({super.key});

  @override
  State<BookmarksListScreen> createState() => _BookmarksListScreenState();
}

class _BookmarksListScreenState extends State<BookmarksListScreen> {
  final DataRepository _repo = DataRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Bookmarks")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _repo.getBookmarks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final bookmarks = snapshot.data ?? [];
          if (bookmarks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text("No bookmarked questions yet.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final b = bookmarks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(b['question'] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          if (b['category'] != null)
                             _buildBadge(b['category'], Colors.blue.shade100, Colors.blue.shade800),
                          if (b['topic'] != null)
                             _buildBadge(b['topic'], Colors.orange.shade100, Colors.orange.shade800),
                          if (b['levelName'] != null)
                             _buildBadge(b['levelName'], Colors.green.shade100, Colors.green.shade800),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await _repo.toggleBookmark(Map<String, dynamic>.from(b));
                        setState(() {});
                      },
                    ),
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getString('user_id') ?? "";
                      
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserLevelQuestionsScreen(
                              category: b['category'] ?? "",
                              subCategory: b['subCategory'] ?? "",
                              topicName: b['topic'] ?? "",
                              levelName: b['levelName'] ?? "",
                              mode: "Practice",
                              userId: userId,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 10, color: textCol, fontWeight: FontWeight.bold)),
    );
  }
}
