import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/api.dart';

class UserResultsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserResultsScreen({super.key, required this.userId, required this.userName});

  @override
  State<UserResultsScreen> createState() => _UserResultsScreenState();
}

class _UserResultsScreenState extends State<UserResultsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _progress = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    try {
      final response = await _apiService.getUserProgress(widget.userId);
      setState(() {
        _progress = response.data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Results for ${widget.userName}")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _progress.isEmpty
              ? const Center(child: Text("No progress data found."))
              : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Test Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text("Topic")),
                          DataColumn(label: Text("Level")),
                          DataColumn(label: Text("Score")),
                          DataColumn(label: Text("Percentage")),
                          DataColumn(label: Text("Date")),
                        ],
                        rows: _progress.map((p) {
                          final date = p['timestamp'] != null 
                              ? DateTime.parse(p['timestamp']).toLocal().toString().split('.')[0]
                              : 'N/A';
              
                          return DataRow(cells: [
                            DataCell(Text(p['topic'] ?? '-')),
                            DataCell(Text(p['level'] ?? '-')),
                            DataCell(Text(p['score']?.toString() ?? '-')), // Added .toString()
                            DataCell(Text(p['percentage'] != null
                                ? "${double.parse(p['percentage'].toString()).toStringAsFixed(1)}%"
                                : '-')),
                            DataCell(Text(date)),
                          ]);
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 48),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Bookmarked Questions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    FutureBuilder<Response>(
                      future: _apiService.getUserBookmarks(widget.userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ));
                        }
                        final bookmarks = snapshot.data?.data as List? ?? [];
                        if (bookmarks.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text("No bookmarks found."),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: bookmarks.length,
                          itemBuilder: (context, index) {
                            final b = bookmarks[index];
                            return ListTile(
                              title: Text(b['question']?.toString() ?? "Unknown Question"), 
                              subtitle: Text("Topic: ${b['topic'] ?? 'N/A'} | Level: ${b['levelName'] ?? 'N/A'}"),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }
}
