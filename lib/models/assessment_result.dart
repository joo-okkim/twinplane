import 'assessment_question.dart';

/// A single graded question, returned only after submission -- unlike
/// [AssessmentQuestion], this carries the revealed correct answer,
/// explanation, and per-question feedback.
class AssessmentQuestionResult {
  final int id;
  final int sequence;
  final AssessmentQuestionType type;
  final String question;
  final List<String> choices;
  final String studentAnswer;
  final bool isCorrect;
  final String correctAnswer;
  final String explanation;
  final String feedback;

  const AssessmentQuestionResult({
    required this.id,
    required this.sequence,
    required this.type,
    required this.question,
    required this.choices,
    required this.studentAnswer,
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
    required this.feedback,
  });

  factory AssessmentQuestionResult.fromJson(Map<String, dynamic> json) => AssessmentQuestionResult(
        id: json['id'] as int,
        sequence: json['sequence'] as int,
        type: AssessmentQuestionType.fromWire(json['type'] as String),
        question: json['question'] as String,
        choices: (json['choices'] as List).map((e) => e as String).toList(),
        studentAnswer: json['studentAnswer'] as String,
        isCorrect: json['isCorrect'] as bool,
        correctAnswer: json['correctAnswer'] as String,
        explanation: json['explanation'] as String,
        feedback: json['feedback'] as String,
      );
}
