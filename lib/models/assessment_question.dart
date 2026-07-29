enum AssessmentQuestionType {
  multipleChoice('multiple_choice'),
  shortAnswer('short_answer');

  final String wireValue;
  const AssessmentQuestionType(this.wireValue);

  static AssessmentQuestionType fromWire(String value) => AssessmentQuestionType.values
      .firstWhere((t) => t.wireValue == value, orElse: () => AssessmentQuestionType.shortAnswer);
}

/// A single generated question, before it's been answered. Mirrors
/// POST /api/assessments/generate's `questions[]` shape -- correctAnswer/
/// explanation are withheld by the backend until submission, so they have
/// no place here (see AssessmentQuestionResult for the graded shape).
class AssessmentQuestion {
  final int id;
  final int sequence;
  final AssessmentQuestionType type;
  final String question;
  final List<String> choices;

  const AssessmentQuestion({
    required this.id,
    required this.sequence,
    required this.type,
    required this.question,
    required this.choices,
  });

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) => AssessmentQuestion(
        id: json['id'] as int,
        sequence: json['sequence'] as int,
        type: AssessmentQuestionType.fromWire(json['type'] as String),
        question: json['question'] as String,
        choices: (json['choices'] as List).map((e) => e as String).toList(),
      );
}
