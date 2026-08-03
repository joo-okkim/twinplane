import '../models/allowance_policy.dart';
import '../models/assessment_generate_request.dart';
import '../models/assessment_generate_response.dart';
import '../models/assessment_submit_request.dart';
import '../models/assessment_submit_response.dart';
import '../models/daily_plan_response.dart';
import '../models/daily_review_request.dart';
import '../models/daily_review_response.dart';
import '../models/exam_info.dart';
import '../models/incomplete_plan.dart';
import '../models/modification_request.dart';
import '../models/modification_result.dart';
import '../models/parent_settings.dart';
import '../models/sticker_policy.dart';
import '../models/student_profile.dart';

/// Contract for the AI Teacher backend. See docs/API_CONTRACT.md for the
/// REST endpoint each method/getter maps to once a real server exists.
/// [MockAiTeacherRepository] is the implementation used today;
/// [HttpAiTeacherRepository] (lib/services/http/) implements this same
/// interface against the real Node API without touching providers or
/// screens -- only `main.dart`'s repository choice changes.
abstract class AiTeacherRepository {
  /// Must be awaited once before any other member is read. The mock
  /// implementation is a no-op; the HTTP implementation uses this to fetch
  /// and cache the student's profile/policies (GET /api/student/*,
  /// GET /api/policy/*) so the synchronous getters below have data to
  /// return. Providers call this during app startup, before the first
  /// screen builds.
  Future<void> initialize();

  /// Display name for the greeting header. A real backend would return this
  /// as part of the authenticated student's profile.
  String get studentName;

  /// Current streak (spec's recentPerformance.consecutiveCompletionDays).
  int get streakDays;

  /// Spec's recentPerformance.weeklyAchievementRate, for the home dashboard.
  double get weeklyAchievementRate;

  /// Spec's exams[], for the home dashboard's upcoming-exam countdown.
  List<ExamInfo> get exams;

  /// Spec's subjectLevels[], for the home dashboard's weakest-subject insight.
  List<SubjectLevel> get subjectLevels;

  /// Spec's stickerPolicy, for the reward tab's transparency panel.
  StickerPolicy get stickerPolicy;

  /// Spec's allowancePolicy, for the reward tab's allowance-candidate ladder.
  AllowancePolicy get allowancePolicy;

  /// Spec's student profile, for the 마이(My) tab's profile card.
  StudentProfile get studentProfile;

  /// Spec's parentSettings, for the 마이(My) tab's read-only settings panel.
  ParentSettings get parentSettings;

  Future<DailyPlanResponse> createDailyPlan({
    required DateTime date,
    List<IncompletePlan> carryOver,
    StudentCondition? condition,
  });

  Future<ModificationResult> requestModification(ModificationRequest request);

  Future<DailyReviewResponse> submitDailyReview({
    required DateTime date,
    required List<PlanItemCompletion> completions,
  });

  /// Generates a 이해도 확인 (comprehension check) quiz for a completed,
  /// evidence-required plan item. See POST /api/assessments/generate.
  Future<AssessmentGenerateResponse> generateAssessment(
    AssessmentGenerateRequest request,
  );

  /// Submits answers for grading. See POST /api/assessments/{id}/submit.
  Future<AssessmentSubmitResponse> submitAssessment(
    AssessmentSubmitRequest request,
  );
}
