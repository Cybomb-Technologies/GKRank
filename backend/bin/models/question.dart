class Question {
  final String? id;
  final String question;
  final List<String> options;
  final String answer;
  final String explanation;
  final String? topic;

  Question({
    this.id,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
    this.topic,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'question': question,
      'options': options,
      'answer': answer,
      'explanation': explanation,
      if (topic != null) 'topic': topic,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      question: json['question'],
      options: List<String>.from(json['options']),
      answer: json['answer'],
      explanation: json['explanation'],
      topic: json['topic'],
    );
  }
}
