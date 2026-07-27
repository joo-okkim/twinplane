import '../../models/allowance_policy.dart';
import '../../models/assignment.dart';
import '../../models/exam_info.dart';
import '../../models/fixed_schedule.dart';
import '../../models/incomplete_plan.dart';
import '../../models/parent_settings.dart';
import '../../models/recent_performance.dart';
import '../../models/sticker_policy.dart';
import '../../models/student_dataset.dart';
import '../../models/student_profile.dart';

/// The single fixed dummy dataset the mock AI Teacher service reasons over.
/// Mirrors the spec's section 11 example student (지윤, MIDDLE_2) so plan
/// generation, modification, and review responses are deterministic and easy
/// to reason about while the real Node API is not yet wired up.
class MockStudentData {
  MockStudentData._();

  static final StudentDataset dataset = StudentDataset(
    student: const StudentProfile(
      studentId: 1001,
      name: '지윤',
      gradeLevel: 'MIDDLE_2',
      wakeUpTime: '07:00',
      bedTime: '22:30',
      preferredStudyStartTime: '16:30',
      maxSelfStudyMinutes: 150,
      maxConcentrationMinutes: 40,
      condition: StudentCondition.normal,
      conditionMemo: '학교 체육활동이 있었음',
    ),
    subjectLevels: const [
      SubjectLevel(
        subject: '수학',
        level: 'normal',
        recentAchievementRate: 68,
        averageDelayMinutes: 15,
        averageActualMinutes: 42,
        recentIncompleteCount: 2,
      ),
      SubjectLevel(
        subject: '영어',
        level: 'good',
        recentAchievementRate: 85,
        averageDelayMinutes: 5,
        averageActualMinutes: 28,
        recentIncompleteCount: 0,
      ),
      SubjectLevel(
        subject: '과학',
        level: 'normal',
        recentAchievementRate: 76,
        averageDelayMinutes: 10,
        averageActualMinutes: 30,
        recentIncompleteCount: 1,
      ),
    ],
    fixedSchedules: const [
      FixedSchedule(title: '학교', startTime: '08:00', endTime: '15:30', type: 'school'),
      FixedSchedule(title: '영어학원', startTime: '17:30', endTime: '19:00', type: 'academy'),
      FixedSchedule(title: '저녁식사', startTime: '19:20', endTime: '20:00', type: 'meal'),
    ],
    assignments: const [
      Assignment(
        assignmentId: 501,
        subject: '수학',
        title: '유형 문제집 42~45쪽',
        dueDate: '2026-07-29',
        estimatedMinutes: 45,
        priority: 'high',
        required: true,
        evidenceRequired: true,
      ),
      Assignment(
        assignmentId: 502,
        subject: '과학',
        title: '수행평가 자료 조사',
        dueDate: '2026-07-30',
        estimatedMinutes: 30,
        priority: 'high',
        required: true,
        evidenceRequired: false,
      ),
      Assignment(
        assignmentId: 503,
        subject: '영어',
        title: '영어 단어 25개',
        dueDate: '2026-07-28',
        estimatedMinutes: 25,
        priority: 'high',
        required: true,
        evidenceRequired: false,
      ),
    ],
    incompletePlans: const [
      IncompletePlan(
        planItemId: 801,
        subject: '수학',
        title: '오답 10문제 복습',
        originalDate: '2026-07-27',
        estimatedMinutes: 30,
        completionRate: 0,
        reason: '피곤해서 시작하지 못함',
        priority: 'normal',
      ),
    ],
    exams: const [
      ExamInfo(
        examName: '2학기 수학 단원평가',
        subject: '수학',
        examDate: '2026-08-05',
        scope: '일차함수',
        importance: 'high',
      ),
    ],
    recentPerformance: const RecentPerformance(
      dailyAchievementRate7Days: 72,
      weeklyAchievementRate: 75,
      consecutiveCompletionDays: 2,
      mostCompletedSubject: '영어',
      leastCompletedSubject: '수학',
      averageStartDelayMinutes: 12,
    ),
    parentSettings: const ParentSettings(
      planApprovalMode: 'STUDENT_CONFIRM',
      maxDailyStudyMinutes: 150,
      allowPlanAutoAdjustment: true,
      allowStudentTimeChange: true,
      allowStudentQuantityChange: true,
      requireParentApprovalForRequiredPlanDeletion: true,
    ),
    stickerPolicy: const StickerPolicy(
      requiredPlanCompletion: 2,
      recommendedPlanCompletion: 1,
      onTimeBonus: 1,
      dailyAchievement80Bonus: 3,
      allRequiredCompletionBonus: 2,
    ),
    allowancePolicy: const AllowancePolicy(
      enabled: true,
      period: 'WEEKLY',
      conditions: [
        AllowanceCondition(achievementRate: 80, amount: 5000),
        AllowanceCondition(achievementRate: 90, amount: 10000),
      ],
      parentApprovalRequired: true,
    ),
  );
}
