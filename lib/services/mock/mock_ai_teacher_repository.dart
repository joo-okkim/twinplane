import 'dart:math';

import '../../models/allowance_policy.dart';
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
}
