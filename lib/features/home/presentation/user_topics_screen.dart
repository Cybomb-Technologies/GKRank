import 'package:flutter/material.dart';
import '../../../core/api.dart';
import '../../../core/data_repository.dart';
import '../../../core/widgets/fade_in_animation.dart';
import '../../../core/widgets/premium_card.dart';
import 'user_level_questions_screen.dart';

class UserTopicsScreen extends StatefulWidget {
  final String categoryName;

  const UserTopicsScreen({
    super.key, 
    required this.categoryName,
  });

  @override
  State<UserTopicsScreen> createState() => _UserTopicsScreenState();
}

class _UserTopicsScreenState extends State<UserTopicsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final DataRepository _dataRepo = DataRepository();
  bool _isLoading = true;
  List<dynamic> _topics = [];
  late TabController _tabController;
  
  Map<String, bool> _topicCompletion = {};
  Map<String, Map<String, bool>> _modeCompletion = {}; // topicName -> {mode -> isComplete}
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final userSession = await _dataRepo.getUserSession();
      _currentUserId = userSession?['_id'];
      
      final response = await _apiService.getTopics(widget.categoryName);
      if (mounted) {
        setState(() {
          _topics = response.data;
        });
        await _checkProgress();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkProgress() async {
    if (_currentUserId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    // Get all progress data
    final allProgress = await _dataRepo.getAllProgress();
    
    // Check each topic for completion across all 3 modes
    Map<String, bool> completionMap = {};
    Map<String, Map<String, bool>> modeCompletionMap = {};
    
    for (var topic in _topics) {
      final String topicName = topic is Map ? topic['name'] : topic.toString();
      
      // Check if all 3 modes are completed
      bool learnComplete = false;
      bool practiceComplete = false;
      bool testComplete = false;
      
      for (var progress in allProgress) {
        if (progress['topic'] == topicName) {
          final mode = progress['mode'] ?? '';
          final completed = progress['completed'] ?? false;
          
          if (mode == 'Learn' && completed) learnComplete = true;
          if (mode == 'Practice' && completed) practiceComplete = true;
          if (mode == 'Test' && completed) testComplete = true;
        }
      }
      
      // Store individual mode completion
      modeCompletionMap[topicName] = {
        'Learn': learnComplete,
        'Practice': practiceComplete,
        'Test': testComplete,
      };
      
      // Topic is complete only if all 3 modes are complete
      completionMap[topicName] = learnComplete && practiceComplete && testComplete;
    }
    
    if (mounted) {
      setState(() {
        _topicCompletion = completionMap;
        _modeCompletion = modeCompletionMap;
        _isLoading = false;
      });
    }
  }

  void _onTopicTap(String topicName, String mode) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserLevelQuestionsScreen(
          category: widget.categoryName,
          subCategory: "",
          topicName: topicName,
          levelName: "",
          mode: mode,
          userId: _currentUserId ?? "",
        ),
      ),
    );
    _checkProgress();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(text: "Learn"),
            Tab(text: "Practice"),
            Tab(text: "Test"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTopicList("Learn"),
                _buildTopicList("Practice"),
                _buildTopicList("Test"),
              ],
            ),
    );
  }

  Widget _buildTopicList(String mode) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    Color modeColor = mode == "Learn" ? Colors.blue : (mode == "Practice" ? Colors.orange : Colors.red);

    if (_topics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.topic_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text("No topics available", style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topics.length,
      itemBuilder: (context, index) {
        final topicData = _topics[index];
        final String topicName = topicData is Map ? topicData['name'] : topicData.toString();
        // USE THIS: Check completion for the current tab's mode only
        final isCompleted = _modeCompletion[topicName]?[mode] ?? false;

        return FadeInAnimation(
          delay: Duration(milliseconds: index * 100),
          child: PremiumCard(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            onTap: () => _onTopicTap(topicName, mode),
            title: '',
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: modeColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        mode == "Learn" ? Icons.school_rounded : (mode == "Practice" ? Icons.fitness_center_rounded : Icons.quiz_rounded),
                        color: modeColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topicName,
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Start ${mode.toLowerCase()}ing",
                            style: TextStyle(fontSize: 13, color: colorScheme.outline),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      const Icon(Icons.check_circle, color: Colors.green, size: 24),
                  ],
                ),
                // Mode completion indicators
                // if (_modeCompletion.containsKey(topicName))
                //   Padding(
                //     padding: const EdgeInsets.only(top: 12.0),
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.end,
                //       children: [
                //         _buildModeIndicator("Learn", _modeCompletion[topicName]!['Learn'] ?? false, Colors.blue),
                //         const SizedBox(width: 8),
                //         _buildModeIndicator("Practice", _modeCompletion[topicName]!['Practice'] ?? false, Colors.orange),
                //         const SizedBox(width: 8),
                //         _buildModeIndicator("Test", _modeCompletion[topicName]!['Test'] ?? false, Colors.red),
                //       ],
                //     ),
                //   ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeIndicator(String mode, bool isComplete, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isComplete ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete ? color : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isComplete ? color : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            mode[0], // First letter (L, P, T)
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isComplete ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
