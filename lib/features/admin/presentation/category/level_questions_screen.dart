import 'package:flutter/material.dart';
import '../../../../core/api.dart';
import '../../../../core/widgets/premium_card.dart';

class LevelQuestionsScreen extends StatefulWidget {
  final String category;
  final String topic;

  const LevelQuestionsScreen({
    super.key,
    required this.category,
    required this.topic,
  });

  @override
  State<LevelQuestionsScreen> createState() => _LevelQuestionsScreenState();
}

class _LevelQuestionsScreenState extends State<LevelQuestionsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  void _fetchQuestions() async {
    setState(() => _isLoading = true);

    print("DEBUG: UI - Calling getQuestions with Topic: '${widget.topic}'");

    try {
      final response = await _apiService.getQuestions(widget.topic);

      print("DEBUG: UI - Response Status Code: ${response.statusCode}");
      print("DEBUG: UI - Response Data Length: ${response.data.length}");

      setState(() {
        _questions = response.data is List ? response.data : [];
        _isLoading = false;
      });
    } catch (e) {
      print("DEBUG: UI ERROR - Failed to fetch: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showAddQuestionDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final qController = TextEditingController();
    final List<TextEditingController> optControllers = List.generate(4, (_) => TextEditingController());
    final ansController = TextEditingController();
    final expController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Question"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qController, 
                decoration: InputDecoration(
                  labelText: "Question",
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ...List.generate(4, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TextField(
                  controller: optControllers[i],
                  decoration: InputDecoration(
                    labelText: "Option ${i + 1}",
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                ),
              )),
              TextField(
                controller: ansController, 
                decoration: InputDecoration(
                  labelText: "Correct Answer",
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: expController, 
                decoration: InputDecoration(
                  labelText: "Explanation (Optional)",
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (qController.text.isEmpty || ansController.text.isEmpty) return;
              
              final newQuestion = {
                "topic": widget.topic,
                "category": widget.category,
                "question": qController.text,
                "options": optControllers.map((c) => c.text).toList(),
                "answer": ansController.text,
                "explanation": expController.text,
              };

              try {
                final response = await _apiService.addQuestion(newQuestion);

                if (mounted && response.statusCode == 200) {
                  Navigator.pop(context);
                  _fetchQuestions(); 
                }
              } catch (e) {
                print("DEBUG: Error in UI during save -> $e");
              }
            },
            child: const Text("Save Question"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.topic, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              "Questions Management",
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
            onPressed: _showAddQuestionDialog,
            tooltip: "Add Question",
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
                  Text("Loading questions...", style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : _buildQuestionsList(),
    );
  }

  Widget _buildQuestionsList() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 80, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 24),
            const Text("No questions found for this topic.", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddQuestionDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text("Add First Question"),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final q = _questions[index];
        return PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Q${index + 1}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q['question'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              ...q['options'].map<Widget>((opt) {
                final bool isCorrect = opt == q['answer'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCorrect 
                        ? Colors.green.withOpacity(0.1) 
                        : colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCorrect ? Colors.green.withOpacity(0.3) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle_rounded : Icons.circle_outlined,
                        color: isCorrect ? Colors.green : colorScheme.outline,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(opt.toString())),
                    ],
                  ),
                );
              }).toList(),
              if (q['explanation'] != null && q['explanation'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_rounded, size: 16, color: Colors.amber),
                          SizedBox(width: 8),
                          Text(
                            "EXPLANATION",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        q['explanation'],
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                )
              ],
            ],
          ),
        );
      },
    );
  }
}