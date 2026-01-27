import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';

class TestReviewScreen extends StatelessWidget {
  final List<dynamic> questions;
  final Map<int, String?> userAnswers;

  const TestReviewScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Answers"),
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) => _buildReviewCard(context, index),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text("Back to Results", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, int index) {
    final q = questions[index];
    final userAnswer = userAnswers[index];
    final correctAnswer = q['answer'];
    final isCorrect = userAnswer == correctAnswer;
    final isAnswered = userAnswer != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Q number and result
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Q ${index + 1}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isAnswered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCorrect 
                          ? const Color(0xFF2EC4B6).withOpacity(0.1) 
                          : Theme.of(context).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? const Color(0xFF2EC4B6) : Theme.of(context).colorScheme.error,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCorrect ? "Correct" : "Wrong",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? const Color(0xFF2EC4B6) : Theme.of(context).colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Not Answered",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Question
            Text(
              q['question'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            
            // Options
            ...((q['options'] as List)).map((opt) {
              final optStr = opt.toString();
              final isCorrectOption = optStr == correctAnswer;
              final isUserSelected = optStr == userAnswer;
              
              Color? bgColor;
              Color? borderColor;
              IconData? icon;
              String? label;
              
              if (isCorrectOption) {
                bgColor = const Color(0xFF2EC4B6).withOpacity(0.15); // Brand Teal
                borderColor = const Color(0xFF2EC4B6);
                icon = Icons.check_circle;
                label = "Correct Answer";
              }
              
              if (isUserSelected && !isCorrect) {
                bgColor = Theme.of(context).colorScheme.error.withOpacity(0.15);
                borderColor = Theme.of(context).colorScheme.error;
                icon = Icons.cancel;
                label = "Your Answer";
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor ?? Colors.grey.withOpacity(0.05),
                  border: Border.all(
                    color: borderColor ?? Colors.grey.withOpacity(0.2),
                    width: borderColor != null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: borderColor, size: 20),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            optStr,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: icon != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (label != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: borderColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            
            // Explanation
            if (q['explanation'] != null && q['explanation'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.brandOrange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppColors.brandOrange, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "EXPLANATION",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandOrange,
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      q['explanation'],
                      style: const TextStyle(fontSize: 14, height: 1.5),
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
}
