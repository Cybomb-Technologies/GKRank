import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/api.dart';
import '../../../core/data_repository.dart';
import 'user_test_result_screen.dart';
import 'test_review_screen.dart';

class UserLevelQuestionsScreen extends StatefulWidget {
  final String topicName;
  final String levelName;
  final String mode; // Learn, Practice, Test
  final String category;
  final String subCategory;
  final String userId;

  const UserLevelQuestionsScreen({
    super.key,
    required this.topicName,
    required this.levelName,
    required this.mode,
    required this.category,
    required this.subCategory,
    required this.userId,
  });

  @override
  State<UserLevelQuestionsScreen> createState() => _UserLevelQuestionsScreenState();
}

class _UserLevelQuestionsScreenState extends State<UserLevelQuestionsScreen> {
  final ApiService _apiService = ApiService();
  final DataRepository _dataRepo = DataRepository();
  final PageController _pageController = PageController();

  bool _isLoading = true;
  List<dynamic> _questions = [];
  Map<int, String?> _selectedAnswers = {};
  int _currentQuestionIndex = 0;
  
  // Test Mode
  bool _isTestStarted = false;
  int _testDurationMinutes = 10;
  bool _isTimed = false;
  Timer? _timer;
  int _remainingSeconds = 0;

  Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
    _fetchBookmarks();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await _apiService.getQuestions(widget.topicName);
      if (mounted) {
        setState(() {
          _questions = response.data;
          _isLoading = false;
        });

        if (widget.mode != 'Test') {
          _loadState();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBookmarks() async {
    final user = await _dataRepo.getUserSession();
    if (user != null) {
      try {
        final bookmarks = await _apiService.getUserBookmarks(user['_id']);
        if (mounted) {
          final List data = bookmarks.data;
          setState(() {
            _bookmarkedIds = data.map((e) => (e['id'] ?? e['_id']).toString()).toSet();
          });
        }
      } catch (e) {
        // Ignore
      }
    }
  }

  Future<void> _loadState() async {
    final savedState = await _dataRepo.getTopicState(widget.topicName, widget.mode);
    if (savedState != null && mounted) {
      setState(() {
        _selectedAnswers = savedState;
      });
    }
  }

  Future<void> _saveState() async {
    if (widget.mode == 'Test') return;
    await _dataRepo.saveTopicState(widget.topicName, widget.mode, _selectedAnswers);
  }

  Future<void> _toggleBookmark(int index) async {
    final q = _questions[index];
    final qId = (q['id'] ?? q['_id']).toString();
    final user = await _dataRepo.getUserSession();

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to bookmark questions")),
        );
      }
      return;
    }

    if (_bookmarkedIds.contains(qId)) {
      await _apiService.removeBookmark(user['_id'], qId);
      setState(() => _bookmarkedIds.remove(qId));
    } else {
      // --- REPLACE THE OLD addBookmark CALL WITH THIS ---
      try {
        await _apiService.addBookmark({
          "userId": user['_id'],               // Use user['_id'] from your session
          "questionId": qId,                  // The question's ID
          "topic": widget.topicName,          // From the widget parameters
          "level": widget.levelName,          // Use widget.levelName
          "questionText": q['question'],      // The actual question text
          "options": q['options'],            // The list of options
          "correctAnswer": q['answer'],        // Map 'answer' from your question object
        });
        setState(() => _bookmarkedIds.add(qId));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save bookmark: $e")),
          );
        }
      }
      // ------------------------------------------------
    }
  }

  void _startTest() {
    setState(() {
      _isTestStarted = true;
      _currentQuestionIndex = 0;
      if (_isTimed) {
        _remainingSeconds = _testDurationMinutes * 60;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_remainingSeconds > 0) {
            setState(() => _remainingSeconds--);
          } else {
            _submitTest();
          }
        });
      }
    });
  }

  void _showSubmitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Submit Test?"),
        content: Text("You have answered ${_selectedAnswers.length} out of ${_questions.length} questions.\n\nAre you sure you want to submit?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitTest();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void _submitTest() async {
    _timer?.cancel();
    
    int correct = 0;
    _selectedAnswers.forEach((index, answer) {
      if (index < _questions.length && _questions[index]['answer'] == answer) {
        correct++;
      }
    });

    await _dataRepo.saveProgress({
      'topic': widget.topicName,
      'mode': 'Test',
      'score': correct,
      'total': _questions.length,
      'completed': true,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserTestResultScreen(
            totalQuestions: _questions.length,
            correctAnswers: correct,
            incorrectAnswers: _questions.length - correct,
            unanswered: _questions.length - _selectedAnswers.length,
            questions: _questions,
            userAnswers: _selectedAnswers,
            onReview: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TestReviewScreen(
                    questions: _questions,
                    userAnswers: _selectedAnswers,
                  ),
                ),
              );
            },
            onFinish: () {
              Navigator.pop(context); // Pop result screen
              Navigator.pop(context); // Pop to topics
            },
          ),
        ),
      );
    }
  }

  void _markAsComplete() async {
    await _dataRepo.saveProgress({
      'topic': widget.topicName,
      'mode': widget.mode,
      'score': widget.mode == 'Practice' ? _calculateScore() : null,
      'total': widget.mode == 'Practice' ? _questions.length : null,
      'completed': true,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${widget.mode} mode completed!")),
      );
      Navigator.pop(context);
    }
  }

  int _calculateScore() {
    int correct = 0;
    _selectedAnswers.forEach((index, answer) {
      if (index < _questions.length && _questions[index]['answer'] == answer) {
        correct++;
      }
    });
    return correct;
  }

  Color _getModeColor() {
    if (widget.mode == 'Learn') return Colors.blue;
    if (widget.mode == 'Practice') return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("No questions found.")),
      );
    }

    if (widget.mode == 'Test' && !_isTestStarted) {
      return _buildTestSetup();
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildUnifiedQuestionView(),
      floatingActionButton: _buildActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final modeColor = _getModeColor();
    
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.topicName, style: const TextStyle(fontSize: 16)),
          Text(
            "Question ${_currentQuestionIndex + 1}/${_questions.length}",
            style: TextStyle(fontSize: 13, color: modeColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        if (widget.mode == 'Test' && _isTimed)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // UNIFIED QUESTION VIEW - Same UI for all modes
  Widget _buildUnifiedQuestionView() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentQuestionIndex = index),
            itemCount: _questions.length,
            itemBuilder: (context, index) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildQuestionCard(index),
            ),
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  // UNIFIED QUESTION CARD with mode-specific behavior
  Widget _buildQuestionCard(int index) {
    final q = _questions[index];
    final userAnswer = _selectedAnswers[index];
    final correctAnswer = q['answer'];
    final isBookmarked = _bookmarkedIds.contains((q['id'] ?? q['_id']).toString());
    final modeColor = _getModeColor();
    
    // Mode-specific flags
    bool showExplanation = false;
    
    if (widget.mode == 'Learn') {
      showExplanation = true;
    } else if (widget.mode == 'Practice' && userAnswer != null) {
      showExplanation = true;
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: modeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Q ${index + 1}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: modeColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? Colors.amber : null,
                  ),
                  onPressed: () => _toggleBookmark(index),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Question Text
            Text(
              q['question'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            
            // Options
            ...((q['options'] as List)).map((opt) {
              final optStr = opt.toString();
              final isCorrect = optStr == correctAnswer;
              final isSelected = optStr == userAnswer;
              
              Color? bgColor;
              Color? borderColor;
              IconData? icon;
              
              // Learn mode: Always show correct answer
              if (widget.mode == 'Learn') {
                if (isCorrect) {
                  bgColor = Colors.green.withOpacity(0.15);
                  borderColor = Colors.green;
                  icon = Icons.check_circle;
                }
              }
              // Practice mode: Show feedback after selection
              else if (widget.mode == 'Practice' && userAnswer != null) {
                if (isCorrect) {
                  bgColor = Colors.green.withOpacity(0.15);
                  borderColor = Colors.green;
                  icon = Icons.check_circle;
                } else if (isSelected) {
                  bgColor = Colors.red.withOpacity(0.15);
                  borderColor = Colors.red;
                  icon = Icons.cancel;
                }
              }
              // Test mode: Just show selection
              else if (widget.mode == 'Test' && isSelected) {
                bgColor = modeColor.withOpacity(0.15);
                borderColor = modeColor;
                icon = Icons.check_circle_outline;
              }
              
              return GestureDetector(
                onTap: (widget.mode == 'Learn') ? null : () {
                  if (widget.mode == 'Practice' && userAnswer != null) return; // Don't allow change in Practice
                  setState(() => _selectedAnswers[index] = optStr);
                  if (widget.mode == 'Practice') _saveState();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor ?? Colors.grey.withOpacity(0.05),
                    border: Border.all(
                      color: borderColor ?? Colors.grey.withOpacity(0.2),
                      width: borderColor != null ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: borderColor, size: 22),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          optStr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: icon != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            
            // Explanation (Learn: always, Practice: after answer)
            if (showExplanation && q['explanation'] != null && q['explanation'].toString().isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "EXPLANATION",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      q['explanation'],
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: _currentQuestionIndex > 0
                ? () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text("Previous"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _currentQuestionIndex < _questions.length - 1
                ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                : null,
            label: const Text("Next"),
            icon: const Icon(Icons.chevron_right),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildActionButton() {
    if (_currentQuestionIndex == _questions.length - 1) {
      if (widget.mode == 'Test') {
        return FloatingActionButton.extended(
          onPressed: _showSubmitDialog,
          label: const Text("Submit Test"),
          icon: const Icon(Icons.send),
          backgroundColor: Colors.red,
        );
      } else {
        // Learn or Practice
        return FloatingActionButton.extended(
          onPressed: _markAsComplete,
          label: const Text("Mark as Complete"),
          icon: const Icon(Icons.check_circle),
          backgroundColor: _getModeColor(),
        );
      }
    }
    return null;
  }

  Widget _buildTestSetup() {
    return Scaffold(
      appBar: AppBar(title: const Text("Start Test")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Topic: ${widget.topicName}", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            Text("Total Questions: ${_questions.length}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 40),
            
            SwitchListTile(
              title: const Text("Timed Test"),
              subtitle: const Text("Set a time limit for this test"),
              value: _isTimed,
              onChanged: (val) => setState(() => _isTimed = val),
            ),
            
            if (_isTimed) ...[
               const SizedBox(height: 20),
               Text("Duration: $_testDurationMinutes minutes", style: const TextStyle(fontSize: 16)),
               Slider(
                 value: _testDurationMinutes.toDouble(),
                 min: 1, max: 60, divisions: 59,
                 label: "$_testDurationMinutes min",
                 onChanged: (val) => setState(() => _testDurationMinutes = val.toInt()),
               ),
            ],
            
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Start Test Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
