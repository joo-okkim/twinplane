// Regenerates the example JSON payloads embedded in docs/API_CONTRACT.md
// from the actual mock repository, so the doc never drifts from the real
// Dart models. Run with: dart run tool/dump_api_examples.dart
// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:twinplane/models/assessment_generate_request.dart';
import 'package:twinplane/models/assessment_submit_request.dart';
import 'package:twinplane/models/daily_review_request.dart';
import 'package:twinplane/models/modification_request.dart';
import 'package:twinplane/services/mock/mock_ai_teacher_repository.dart';

const _encoder = JsonEncoder.withIndent('  ');

Future<void> main() async {
  final repo = MockAiTeacherRepository();
  final date = DateTime(2026, 7, 28);

  print('=== GET /api/student/profile ===');
  print(_encoder.convert(repo.studentProfile.toJson()));

  print('\n=== GET /api/student/subject-levels ===');
  print(_encoder.convert(repo.subjectLevels.map((s) => s.toJson()).toList()));

  print('\n=== GET /api/student/exams ===');
  print(_encoder.convert(repo.exams.map((e) => e.toJson()).toList()));

  print('\n=== GET /api/parent/settings ===');
  print(_encoder.convert(repo.parentSettings.toJson()));

  print('\n=== GET /api/policy/sticker ===');
  print(_encoder.convert(repo.stickerPolicy.toJson()));

  print('\n=== GET /api/policy/allowance ===');
  print(_encoder.convert(repo.allowancePolicy.toJson()));

  print('\n=== POST /api/plans/daily (request) ===');
  print(_encoder.convert({'date': '2026-07-28'}));

  print('\n=== POST /api/plans/daily (response) ===');
  final plan = await repo.createDailyPlan(date: date);
  print(_encoder.convert(plan.toJson()));

  print('\n=== POST /api/plans/modify (request) ===');
  final firstAdjustable = plan.dailyPlans.firstWhere((p) => p.adjustable);
  final modRequest = ModificationRequest(planItemId: firstAdjustable.id, reason: ModificationReason.tired);
  print(_encoder.convert(modRequest.toJson()));

  print('\n=== POST /api/plans/modify (response) ===');
  final modResult = await repo.requestModification(modRequest);
  print(_encoder.convert(modResult.toJson()));

  print('\n=== POST /api/reviews/daily (request) ===');
  final completions = plan.dailyPlans
      .where((p) => p.rewardEligible)
      .map((p) => PlanItemCompletion(planItemId: p.id, completed: true, actualMinutes: p.durationMinutes))
      .toList();
  print(_encoder.convert({
    'date': '2026-07-28',
    'completions': completions.map((c) => c.toJson()).toList(),
  }));

  print('\n=== POST /api/reviews/daily (response) ===');
  final review = await repo.submitDailyReview(date: date, completions: completions);
  print(_encoder.convert(review.toJson()));

  print('\n=== POST /api/assessments/generate (request) ===');
  final evidenceItem = plan.dailyPlans.firstWhere((p) => p.evidenceRequired);
  final generateRequest = AssessmentGenerateRequest(planItemId: evidenceItem.id);
  print(_encoder.convert(generateRequest.toJson()));

  print('\n=== POST /api/assessments/generate (response) ===');
  final generated = await repo.generateAssessment(generateRequest);
  print(_encoder.convert({
    'assessmentId': generated.assessmentId,
    'subject': generated.subject,
    'scope': generated.scope,
    'questions': generated.questions
        .map((q) => {
              'id': q.id,
              'sequence': q.sequence,
              'type': q.type.wireValue,
              'question': q.question,
              'choices': q.choices,
            })
        .toList(),
  }));

  print('\n=== POST /api/assessments/{id}/submit (request) ===');
  final submitRequest = AssessmentSubmitRequest(
    assessmentId: generated.assessmentId,
    answers: generated.questions
        .map((q) => AssessmentAnswerInput(questionId: q.id, answer: q.choices.isNotEmpty ? q.choices.first : '답변'))
        .toList(),
  );
  print(_encoder.convert(submitRequest.toJson()));

  print('\n=== POST /api/assessments/{id}/submit (response) ===');
  final submitted = await repo.submitAssessment(submitRequest);
  print(_encoder.convert({
    'assessmentId': submitted.assessmentId,
    'score': submitted.score,
    'totalQuestions': submitted.totalQuestions,
    'results': submitted.results
        .map((r) => {
              'id': r.id,
              'sequence': r.sequence,
              'type': r.type.wireValue,
              'question': r.question,
              'choices': r.choices,
              'studentAnswer': r.studentAnswer,
              'isCorrect': r.isCorrect,
              'correctAnswer': r.correctAnswer,
              'explanation': r.explanation,
              'feedback': r.feedback,
            })
        .toList(),
  }));
}
