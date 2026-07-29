import 'package:flutter/foundation.dart';

import '../models/assessment_generate_request.dart';
import '../models/assessment_generate_response.dart';
import '../models/assessment_submit_request.dart';
import '../models/assessment_submit_response.dart';
import '../services/ai_teacher_repository.dart';

enum AssessmentPhase { idle, generating, answering, submitting, result, error }

/// Owns the lifecycle of a single 이해도 확인 (comprehension check) attempt:
/// generate -> answer -> submit/grade. Does not extend [DailyReviewProvider]
/// -- this is a separate, self-contained flow with its own async states.
class AssessmentProvider extends ChangeNotifier {
  AssessmentProvider(this._repository);

  final AiTeacherRepository _repository;

  AssessmentPhase _phase = AssessmentPhase.idle;
  AssessmentGenerateResponse? _assessment;
  AssessmentSubmitResponse? _result;
  final Map<int, String> _draftAnswers = {};
  String? _error;

  AssessmentPhase get phase => _phase;
  AssessmentGenerateResponse? get assessment => _assessment;
  AssessmentSubmitResponse? get result => _result;
  String? get error => _error;

  String draftAnswerFor(int questionId) => _draftAnswers[questionId] ?? '';

  bool get allAnswered =>
      _assessment != null && _assessment!.questions.every((q) => (_draftAnswers[q.id] ?? '').trim().isNotEmpty);

  Future<void> generate(String planItemId) async {
    _phase = AssessmentPhase.generating;
    _error = null;
    notifyListeners();
    try {
      _assessment = await _repository.generateAssessment(AssessmentGenerateRequest(planItemId: planItemId));
      _draftAnswers.clear();
      _phase = AssessmentPhase.answering;
    } catch (e) {
      _error = '문제를 불러오지 못했어요. 잠시 후 다시 시도해주세요.';
      _phase = AssessmentPhase.error;
    }
    notifyListeners();
  }

  void setAnswer(int questionId, String answer) {
    _draftAnswers[questionId] = answer;
    notifyListeners();
  }

  Future<void> submit() async {
    final assessment = _assessment;
    if (assessment == null) return;
    _phase = AssessmentPhase.submitting;
    notifyListeners();
    try {
      _result = await _repository.submitAssessment(
        AssessmentSubmitRequest(
          assessmentId: assessment.assessmentId,
          answers: assessment.questions
              .map((q) => AssessmentAnswerInput(questionId: q.id, answer: _draftAnswers[q.id] ?? ''))
              .toList(),
        ),
      );
      _phase = AssessmentPhase.result;
    } catch (e) {
      _error = '채점을 완료하지 못했어요. 잠시 후 다시 시도해주세요.';
      _phase = AssessmentPhase.error;
    }
    notifyListeners();
  }

  void reset() {
    _phase = AssessmentPhase.idle;
    _assessment = null;
    _result = null;
    _draftAnswers.clear();
    _error = null;
    notifyListeners();
  }
}
