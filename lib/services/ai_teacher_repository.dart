import '../models/allowance_policy.dart';
import '../models/daily_plan_response.dart';
import '../models/daily_review_response.dart';
import '../models/exam_info.dart';
import '../models/incomplete_plan.dart';
import '../models/modification_request.dart';
import '../models/modification_result.dart';
import '../models/daily_review_request.dart';
import '../models/parent_settings.dart';
import '../models/sticker_policy.dart';
import '../models/student_profile.dart';

/// Contract for the AI Teacher backend. [MockAiTeacherRepository] is the only
/// implementation today; a future HttpAiTeacherRepository can implement this
/// same interface to call the real Node server without touching providers or
/// screens.
abstract class AiTeacherRepository {
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
}
