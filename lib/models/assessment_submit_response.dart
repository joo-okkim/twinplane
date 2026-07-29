import 'assessment_result.dart';

class AssessmentSubmitResponse {
  final int assessmentId;
  final int score;
  final int totalQuestions;
  final List<AssessmentQuestionResult> results;

  const AssessmentSubmitResponse({
    required this.assessmentId,
    required this.score,
    required this.totalQuestions,
    required this.results,
  });

  factory AssessmentSubmitResponse.fromJson(Map<String, dynamic> json) => AssessmentSubmitResponse(
        assessmentId: json['assessmentId'] as int,
        score: json['score'] as int,
        totalQuestions: json['totalQuestions'] as int,
        results: (json['results'] as List)
            .map((e) => AssessmentQuestionResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
