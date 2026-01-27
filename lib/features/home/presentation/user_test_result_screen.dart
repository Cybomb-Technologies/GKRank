import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/fade_in_animation.dart';

class UserTestResultScreen extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final int unanswered;
  final List<dynamic> questions;
  final Map<int, String?> userAnswers;
  final VoidCallback onReview;
  final VoidCallback onFinish;

  const UserTestResultScreen({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.unanswered,
    required this.questions,
    required this.userAnswers,
    required this.onReview,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    double percentage = (totalQuestions > 0) ? (correctAnswers / totalQuestions) * 100 : 0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Test Results"),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        automaticallyImplyLeading: false, 
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          bool isLandscape = orientation == Orientation.landscape;

          Widget chartSection = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Your Score", style: textTheme.titleMedium?.copyWith(color: colorScheme.outline)),
              const SizedBox(height: 24),
              SizedBox(
                height: isLandscape ? 150 : 200,
                width: isLandscape ? 150 : 200,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    correct: correctAnswers,
                    incorrect: incorrectAnswers,
                    unanswered: unanswered,
                    total: totalQuestions,
                    theme: theme
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${percentage.toStringAsFixed(0)}%", 
                          style: (isLandscape ? textTheme.headlineMedium : textTheme.headlineLarge)?.copyWith(fontWeight: FontWeight.bold)
                        ),
                        Text("Accuracy", style: textTheme.labelSmall?.copyWith(color: colorScheme.outline)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );

          Widget statsAndActions = Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   FadeInAnimation(
                     delay: const Duration(milliseconds: 400),
                     child: _buildStatItem(context, "Correct", correctAnswers, Colors.green),
                   ),
                   FadeInAnimation(
                     delay: const Duration(milliseconds: 500),
                     child: _buildStatItem(context, "Incorrect", incorrectAnswers, colorScheme.error),
                   ),
                   FadeInAnimation(
                     delay: const Duration(milliseconds: 600),
                     child: _buildStatItem(context, "Skipped", unanswered, Colors.orange),
                   ),
                ],
              ),
              const SizedBox(height: 40),
              FadeInAnimation(
                delay: const Duration(milliseconds: 800),
                child: ElevatedButton.icon(
                   style: ElevatedButton.styleFrom(
                     minimumSize: const Size(double.infinity, 50),
                     backgroundColor: colorScheme.primary,
                     foregroundColor: colorScheme.onPrimary
                   ),
                   onPressed: onReview,
                   icon: const Icon(Icons.remove_red_eye),
                   label: const Text("Review Answers")
                ),
              ),
              const SizedBox(height: 16),
              FadeInAnimation(
                delay: const Duration(milliseconds: 900),
                child: OutlinedButton(
                   style: OutlinedButton.styleFrom(
                     minimumSize: const Size(double.infinity, 50),
                     foregroundColor: colorScheme.onSurface
                   ),
                   onPressed: onFinish,
                   child: const Text("Back to Home")
                ),
              )
            ],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: isLandscape 
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: chartSection),
                    const SizedBox(width: 48),
                    Expanded(child: statsAndActions),
                  ],
                )
              : Column(
                  children: [
                    chartSection,
                    const SizedBox(height: 40),
                    statsAndActions,
                  ],
                ),
          );
        }
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, int value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            "$value", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: colorScheme.outline)),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final int correct;
  final int incorrect;
  final int unanswered;
  final int total;
  final ThemeData theme;

  _DonutChartPainter({
    required this.correct, 
    required this.incorrect, 
    required this.unanswered, 
    required this.total,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.12;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;

    // Background track
    paint.color = theme.colorScheme.outlineVariant.withOpacity(0.2);
    canvas.drawCircle(center, radius - strokeWidth / 2, paint);

    // Correct Segment
    if (correct > 0) {
      double sweep = (correct / total) * 2 * pi;
      paint.color = Colors.green;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }

    // Incorrect Segment
    if (incorrect > 0) {
      double sweep = (incorrect / total) * 2 * pi;
      paint.color = theme.colorScheme.error;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }

    // Unanswered Segment
    if (unanswered > 0) {
      double sweep = (unanswered / total) * 2 * pi;
      paint.color = Colors.orange.withOpacity(0.5);
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
