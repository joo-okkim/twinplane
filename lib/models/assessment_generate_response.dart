import 'assessment_question.dart';

class AssessmentGenerateResponse {
  final int assessmentId;
  final String subject;
  final String scope;
  final List<AssessmentQuestion> questions;

  const AssessmentGenerateResponse({
    required this.assessmentId,
    required this.subject,
    required this.scope,
    required this.questions,
  });

  factory AssessmentGenerateResponse.fromJson(Map<String, dynamic> json) => AssessmentGenerateResponse(
        assessmentId: json['assessmentId'] as int,
        subject: json['subject'] as String,
        scope: json['scope'] as String,
        questions:
            (json['questions'] as List).map((e) => AssessmentQuestion.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
