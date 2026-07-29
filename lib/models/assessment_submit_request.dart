class AssessmentAnswerInput {
  final int questionId;
  final String answer;

  const AssessmentAnswerInput({required this.questionId, required this.answer});

  Map<String, dynamic> toJson() => {'questionId': questionId, 'answer': answer};
}

/// assessmentId is used by the repository to build the submit URL
/// (POST /api/assessments/{id}/submit) -- it is not itself part of the
/// request body.
class AssessmentSubmitRequest {
  final int assessmentId;
  final List<AssessmentAnswerInput> answers;

  const AssessmentSubmitRequest({required this.assessmentId, required this.answers});

  Map<String, dynamic> toJson() => {'answers': answers.map((a) => a.toJson()).toList()};
}
