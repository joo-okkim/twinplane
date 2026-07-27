import 'allowance_policy.dart';
import 'assignment.dart';
import 'exam_info.dart';
import 'fixed_schedule.dart';
import 'incomplete_plan.dart';
import 'parent_settings.dart';
import 'recent_performance.dart';
import 'sticker_policy.dart';
import 'student_profile.dart';

/// Aggregates the fixed dummy input dataset that stands in for what a real
/// Node API would fetch per-student before generating a plan. All fields
/// mirror the `CREATE_DAILY_PLAN` input contract from the AI Teacher spec.
class StudentDataset {
  final StudentProfile student;
  final List<SubjectLevel> subjectLevels;
  final List<FixedSchedule> fixedSchedules;
  final List<Assignment> assignments;
  final List<IncompletePlan> incompletePlans;
  final List<ExamInfo> exams;
  final RecentPerformance recentPerformance;
  final ParentSettings parentSettings;
  final StickerPolicy stickerPolicy;
  final AllowancePolicy allowancePolicy;

  const StudentDataset({
    required this.student,
    required this.subjectLevels,
    required this.fixedSchedules,
    required this.assignments,
    required this.incompletePlans,
    required this.exams,
    required this.recentPerformance,
    required this.parentSettings,
    required this.stickerPolicy,
    required this.allowancePolicy,
  });

  SubjectLevel? subjectLevelFor(String subject) {
    for (final s in subjectLevels) {
      if (s.subject == subject) return s;
    }
    return null;
  }
}
