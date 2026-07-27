import '../models/daily_plan_response.dart';
import '../models/daily_review_response.dart';
import '../models/incomplete_plan.dart';
import '../models/modification_request.dart';
import '../models/modification_result.dart';
import '../models/daily_review_request.dart';

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

  Future<DailyPlanResponse> createDailyPlan({
    required DateTime date,
    List<IncompletePlan> carryOver,
  });

  Future<ModificationResult> requestModification(ModificationRequest request);

  Future<DailyReviewResponse> submitDailyReview({
    required DateTime date,
    required List<PlanItemCompletion> completions,
  });
}
