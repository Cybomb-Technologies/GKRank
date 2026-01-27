import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/api.dart';
import '../../../../core/widgets/premium_card.dart';
import 'level_questions_screen.dart';

class CategoryDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> category;

  const CategoryDetailsScreen({super.key, required this.category});

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _topicController = TextEditingController();
  List<dynamic> _topics = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    try {
      final response = await _apiService.getTopics(widget.category['name']);
      setState(() {
        _topics = response.data;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshTopics() async {
    setState(() => _isRefreshing = true);
    await _fetchTopics();
  }

  Future<void> _addTopic() async {
    final name = _topicController.text.trim();
    final categoryName = widget.category['name'];

    if (name.isEmpty) return;

    try {
      final response = await _apiService.addTopic(categoryName, name);
      if (response.statusCode == 200) {
        _topicController.clear();
        Navigator.pop(context);
        _fetchTopics();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.topic_rounded,
            size: 80,
            color: colorScheme.outline.withOpacity(0.2),
          ),
          const SizedBox(height: 24),
          Text(
            "No Topics Yet",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add your first topic to start adding questions",
            style: TextStyle(color: colorScheme.outline),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text("Add Topic"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      onTap: () {
        // Navigate to Question Management for this Topic
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LevelQuestionsScreen(
              category: widget.category['name'],
              topic: topic['name'],
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.tertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.library_books_rounded,
                color: colorScheme.tertiary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic['name'] ?? 'Unnamed',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Manage questions",
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.outline.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Topic"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: "Topic Name",
                hintText: "e.g., History, Science",
                prefixIcon: const Icon(Icons.topic_rounded),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: _addTopic,
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category['name'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Topic Management",
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.outline,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddDialog,
            tooltip: "Add Topic",
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _refreshTopics,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text("Loading topics...", style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshTopics,
              child: _topics.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Summary Card
                        PremiumCard(
                          color: colorScheme.secondaryContainer.withOpacity(0.3),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.topic_rounded,
                                  size: 32,
                                  color: colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Total Topics",
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _topics.length.toString(),
                                    style: textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // List Header
                        Text(
                          "All Topics",
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Topics List
                        ...List.generate(_topics.length, (index) {
                          final topic = _topics[index];
                          return _buildTopicCard(topic, index);
                        }),
                        
                        const SizedBox(height: 80),
                      ],
                    ),
            ),
    );
  }
}

