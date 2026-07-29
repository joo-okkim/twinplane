import 'dart:math';

import '../../models/allowance_policy.dart';
import '../../models/assessment_generate_request.dart';
import '../../models/assessment_generate_response.dart';
import '../../models/assessment_question.dart';
import '../../models/assessment_result.dart';
import '../../models/assessment_submit_request.dart';
import '../../models/assessment_submit_response.dart';
import '../../models/daily_plan_response.dart';
import '../../models/daily_review_request.dart';
import '../../models/daily_review_response.dart';
import '../../models/exam_info.dart';
import '../../models/incomplete_plan.dart';
import '../../models/parent_settings.dart';
import '../../models/sticker_policy.dart';
import '../../models/student_profile.dart';
import '../../models/modification_request.dart';
import '../../models/modification_result.dart';
import '../../models/student_dataset.dart';
import '../ai_teacher_repository.dart';
import 'mock_student_data.dart';
import 'modification_logic.dart';
import 'plan_generation_logic.dart';
import 'review_logic.dart';

class _MockAssessmentQuestion {
  const _MockAssessmentQuestion({
    required this.id,
    required this.sequence,
    required this.type,
    required this.question,
    required this.choices,
    required this.correctAnswer,
    required this.explanation,
  });

  final int id;
  final int sequence;
  final AssessmentQuestionType type;
  final String question;
  final List<String> choices;
  final String correctAnswer;
  final String explanation;
}

class _MockAssessment {
  _MockAssessment({required this.id, required this.subject, required this.scope, required this.questions});

  final int id;
  final String subject;
  final String scope;
  final List<_MockAssessmentQuestion> questions;
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Stands in for the future Node.js/LLM-backed server. Holds one fixed
/// [StudentDataset] and keeps an in-memory per-date plan cache so a
/// modification or review request can look up the plan it acts on, mimicking
/// a stateful backend without any real network calls.
class MockAiTeacherRepository implements AiTeacherRepository {
  MockAiTeacherRepository({StudentDataset? dataset}) : _dataset = dataset ?? MockStudentData.dataset;

  final StudentDataset _dataset;
  final Map<String, DailyPlanResponse> _plansByDate = {};
  final Random _random = Random();

  // Deterministic canned quiz/grading -- no real LLM call, so USE_MOCK=true
  // stays stable for dev/tests. Keyed by assessmentId, mirroring
  // _plansByDate's pattern.
  final Map<int, _MockAssessment> _assessmentsById = {};
  int _nextAssessmentId = 1;

  @override
  Future<void> initialize() async {}

  @override
  String get studentName => _dataset.student.name;

  @override
  int get streakDays => _dataset.recentPerformance.consecutiveCompletionDays;

  @override
  double get weeklyAchievementRate => _dataset.recentPerformance.weeklyAchievementRate;

  @override
  List<ExamInfo> get exams => _dataset.exams;

  @override
  List<SubjectLevel> get subjectLevels => _dataset.subjectLevels;

  @override
  StickerPolicy get stickerPolicy => _dataset.stickerPolicy;

  @override
  AllowancePolicy get allowancePolicy => _dataset.allowancePolicy;

  @override
  StudentProfile get studentProfile => _dataset.student;

  @override
  ParentSettings get parentSettings => _dataset.parentSettings;

  Future<void> _simulateLatency() =>
      Future.delayed(Duration(milliseconds: 400 + _random.nextInt(400)));

  @override
  Future<DailyPlanResponse> createDailyPlan({
    required DateTime date,
    List<IncompletePlan> carryOver = const [],
    StudentCondition? condition,
  }) async {
    await _simulateLatency();
    final key = _dateKey(date);
    final response = PlanGenerationLogic.generate(
      dataset: _dataset,
      date: date,
      carryOverOverride: carryOver.isEmpty ? null : carryOver,
      condition: condition,
    );
    _plansByDate[key] = response;
    return response;
  }

  @override
  Future<ModificationResult> requestModification(ModificationRequest request) async {
    await _simulateLatency();
    DailyPlanResponse? plan;
    String? key;
    for (final entry in _plansByDate.entries) {
      if (entry.value.dailyPlans.any((p) => p.id == request.planItemId)) {
        plan = entry.value;
        key = entry.key;
        break;
      }
    }
    if (plan == null || key == null) {
      return const ModificationResult(
        status: ModificationStatus.parentApprovalRequired,
        updatedItem: null,
        message: '해당 계획을 찾을 수 없어요.',
        reason: '오늘 생성된 계획이 아니에요.',
      );
    }

    final item = plan.dailyPlans.firstWhere((p) => p.id == request.planItemId);
    final result = ModificationLogic.decide(
      item: item,
      request: request,
      parentSettings: _dataset.parentSettings,
    );

    if (result.status == ModificationStatus.applied && result.updatedItem != null) {
      final newPlans = plan.dailyPlans
          .map((p) => p.id == request.planItemId ? result.updatedItem! : p)
          .toList();
      _plansByDate[key] = plan.copyWithPlans(newPlans);
    } else if (result.status == ModificationStatus.removed) {
      final newPlans = plan.dailyPlans.where((p) => p.id != request.planItemId).toList();
      _plansByDate[key] = plan.copyWithPlans(newPlans);
    }

    return result;
  }

  @override
  Future<DailyReviewResponse> submitDailyReview({
    required DateTime date,
    required List<PlanItemCompletion> completions,
  }) async {
    await _simulateLatency();
    final key = _dateKey(date);
    final plan = _plansByDate[key];
    final items = plan?.dailyPlans ?? const [];
    return ReviewLogic.compute(
      dataset: _dataset,
      date: date,
      planItems: items,
      completions: completions,
    );
  }

  /// Exposes the current in-memory plan for a date, used by providers that
  /// need the latest item list (e.g. after a modification) without another
  /// round trip.
  DailyPlanResponse? currentPlanFor(DateTime date) => _plansByDate[_dateKey(date)];

  @override
  Future<AssessmentGenerateResponse> generateAssessment(AssessmentGenerateRequest request) async {
    await _simulateLatency();
    final item = _plansByDate.values
        .expand((plan) => plan.dailyPlans)
        .firstWhere((p) => p.id == request.planItemId);

    final subject = item.subject ?? '학습';
    final scope = item.description;
    final assessmentId = _nextAssessmentId++;
    final questions = _cannedQuestions(assessmentId: assessmentId, subject: subject, scope: scope);
    _assessmentsById[assessmentId] = _MockAssessment(id: assessmentId, subject: subject, scope: scope, questions: questions);

    return AssessmentGenerateResponse(
      assessmentId: assessmentId,
      subject: subject,
      scope: scope,
      questions: questions
          .map((q) => AssessmentQuestion(id: q.id, sequence: q.sequence, type: q.type, question: q.question, choices: q.choices))
          .toList(),
    );
  }

  @override
  Future<AssessmentSubmitResponse> submitAssessment(AssessmentSubmitRequest request) async {
    await _simulateLatency();
    final assessment = _assessmentsById[request.assessmentId]!;
    final answerByQuestionId = {for (final a in request.answers) a.questionId: a.answer};

    final results = assessment.questions.map((q) {
      final studentAnswer = answerByQuestionId[q.id] ?? '';
      final isCorrect = q.type == AssessmentQuestionType.multipleChoice
          ? studentAnswer.trim() == q.correctAnswer.trim()
          // Mock grading has no real LLM to judge free text -- always accept
          // a non-empty short answer, matching the point of a mock: never
          // block dev/tests on subjective grading.
          : studentAnswer.trim().isNotEmpty;
      return AssessmentQuestionResult(
        id: q.id,
        sequence: q.sequence,
        type: q.type,
        question: q.question,
        choices: q.choices,
        studentAnswer: studentAnswer,
        isCorrect: isCorrect,
        correctAnswer: q.correctAnswer,
        explanation: q.explanation,
        feedback: isCorrect ? '정답이에요!' : '아쉬워요. 정답은 "${q.correctAnswer}"예요. ${q.explanation}',
      );
    }).toList();

    final correctCount = results.where((r) => r.isCorrect).length;
    final score = results.isEmpty ? 0 : ((correctCount / results.length) * 100).round();

    return AssessmentSubmitResponse(
      assessmentId: assessment.id,
      score: score,
      totalQuestions: results.length,
      results: results,
    );
  }

  List<_MockAssessmentQuestion> _cannedQuestions({required int assessmentId, required String subject, required String scope}) {
    final base = assessmentId * 100;
    return [
      _MockAssessmentQuestion(
        id: base + 1,
        sequence: 1,
        type: AssessmentQuestionType.multipleChoice,
        question: '$subject 학습 범위($scope)와 가장 관련 있는 활동은 무엇일까요?',
        choices: const ['오늘 배운 내용 복습하기', '관련 없는 영상 시청하기', '다른 과목 숙제하기', '아무것도 하지 않기'],
        correctAnswer: '오늘 배운 내용 복습하기',
        explanation: '학습한 범위를 스스로 복습하는 것이 이해도를 높이는 가장 좋은 방법이에요.',
      ),
      _MockAssessmentQuestion(
        id: base + 2,
        sequence: 2,
        type: AssessmentQuestionType.multipleChoice,
        question: '"$scope"를 공부할 때 가장 중요한 태도는 무엇일까요?',
        choices: const ['이해될 때까지 차근차근 풀어보기', '답만 빨리 베끼기', '어려우면 바로 포기하기', '건너뛰고 다음으로 넘어가기'],
        correctAnswer: '이해될 때까지 차근차근 풀어보기',
        explanation: '차근차근 원리를 이해하며 푸는 습관이 실력을 키워줘요.',
      ),
      _MockAssessmentQuestion(
        id: base + 3,
        sequence: 3,
        type: AssessmentQuestionType.shortAnswer,
        question: '오늘 "$scope" 범위에서 배운 내용을 한 문장으로 설명해보세요.',
        choices: const [],
        correctAnswer: '학생마다 다를 수 있어요',
        explanation: '핵심 개념을 자신의 말로 설명할 수 있으면 잘 이해한 거예요.',
      ),
      _MockAssessmentQuestion(
        id: base + 4,
        sequence: 4,
        type: AssessmentQuestionType.shortAnswer,
        question: '"$scope"와 관련해서 아직 헷갈리는 부분이 있다면 적어보세요.',
        choices: const [],
        correctAnswer: '학생마다 다를 수 있어요',
        explanation: '헷갈리는 부분을 스스로 인지하는 것도 학습의 중요한 과정이에요.',
      ),
      _MockAssessmentQuestion(
        id: base + 5,
        sequence: 5,
        type: AssessmentQuestionType.multipleChoice,
        question: '$subject 학습을 마친 후 가장 먼저 해야 할 일은 무엇일까요?',
        choices: const ['배운 내용 정리하고 확인하기', '바로 잊어버리기', '틀린 부분 확인 안 하기', '아무 계획 없이 쉬기'],
        correctAnswer: '배운 내용 정리하고 확인하기',
        explanation: '배운 내용을 정리하고 확인하는 습관이 장기 기억에 도움이 돼요.',
      ),
    ];
  }
}
