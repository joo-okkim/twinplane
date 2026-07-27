import '../../models/daily_review_request.dart';
import '../../models/daily_review_response.dart';
import '../../models/plan_item.dart';
import '../../models/student_dataset.dart';
import 'message_bank.dart';

/// Rule-based dummy evaluation implementing spec section 15/16: completed
/// items are always mentioned first, incomplete items are described gently
/// (never blamed), and reward/allowance figures are computed from policy but
/// parentApprovalRequired always stays true -- the AI never confirms payout.
class ReviewLogic {
  static DailyReviewResponse compute({
    required StudentDataset dataset,
    required DateTime date,
    required List<PlanItem> planItems,
    required List<PlanItemCompletion> completions,
  }) {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final completionById = {for (final c in completions) c.planItemId: c};

    final scored = planItems.where((p) => p.rewardEligible).toList();
    final total = scored.length;
    final completedItems =
        scored.where((p) => completionById[p.id]?.completed == true).toList();
    final requiredItems = scored.where((p) => p.required).toList();
    final completedRequired =
        requiredItems.where((p) => completionById[p.id]?.completed == true).toList();

    final overallRate = total == 0 ? 0 : ((completedItems.length / total) * 100).round();
    final requiredRate =
        requiredItems.isEmpty ? 100 : ((completedRequired.length / requiredItems.length) * 100).round();

    int onTimeCount = 0;
    for (final p in completedItems) {
      final actual = completionById[p.id]?.actualMinutes ?? p.durationMinutes;
      if (actual <= p.durationMinutes * 1.1) onTimeCount++;
    }
    final onTimeRate = completedItems.isEmpty ? 100 : ((onTimeCount / completedItems.length) * 100).round();

    final totalPlanned = scored.fold(0, (sum, p) => sum + p.durationMinutes);
    final totalActual = completedItems.fold(
        0, (sum, p) => sum + (completionById[p.id]?.actualMinutes ?? p.durationMinutes));

    final subjects = <String>{for (final p in scored) if (p.subject != null) p.subject!};
    final subjectResults = <SubjectResult>[];
    for (final subject in subjects) {
      final items = scored.where((p) => p.subject == subject).toList();
      final done = items.where((p) => completionById[p.id]?.completed == true).toList();
      final planned = items.fold(0, (sum, p) => sum + p.durationMinutes);
      final actual =
          done.fold(0, (sum, p) => sum + (completionById[p.id]?.actualMinutes ?? p.durationMinutes));
      final rate = items.isEmpty ? 0 : ((done.length / items.length) * 100).round();
      String analysis;
      if (done.length < items.length) {
        analysis = MessageBank.reviewIncompleteGentle(items.first.title);
      } else if (actual > planned) {
        analysis = MessageBank.reviewSlowerThanPlanned(subject, actual - planned);
      } else if (actual < planned) {
        analysis = MessageBank.reviewFasterThanPlanned(subject);
      } else {
        analysis = '계획한 시간 내에 완료했습니다.';
      }
      subjectResults.add(SubjectResult(
        subject: subject,
        plannedMinutes: planned,
        actualMinutes: actual,
        achievementRate: rate,
        analysis: analysis,
      ));
    }

    final completedWell = <String>[
      if (requiredRate == 100) MessageBank.reviewCompletedRequired(),
      ...completedItems.take(3).map((p) => MessageBank.reviewCompletedItem(p.title)),
    ];

    final incomplete = scored.where((p) => completionById[p.id]?.completed != true).toList();
    final improvementPoints = <String>[
      ...incomplete.take(3).map((p) => MessageBank.reviewIncompleteGentle(p.title)),
    ];
    for (final result in subjectResults) {
      if (result.actualMinutes > result.plannedMinutes) {
        improvementPoints.add(
            MessageBank.reviewSlowerThanPlanned(result.subject, result.actualMinutes - result.plannedMinutes));
      }
    }

    final studentMessage =
        '${completedWell.isNotEmpty ? completedWell.first : ''} ${MessageBank.reviewEncouragement(overallRate)}'
            .trim();
    final parentMessage =
        '전체 달성률은 $overallRate%, 필수 계획 달성률은 $requiredRate%입니다. '
        '${subjectResults.isNotEmpty ? subjectResults.first.analysis : ''}'
            .trim();

    final policy = dataset.stickerPolicy;
    var earnedStickers = 0;
    earnedStickers += completedRequired.length * policy.requiredPlanCompletion;
    earnedStickers +=
        completedItems.where((p) => p.planType.wireValue == 'recommended').length * policy.recommendedPlanCompletion;
    if (onTimeRate == 100 && completedItems.isNotEmpty) earnedStickers += policy.onTimeBonus;
    final dailyBonusApplied = overallRate >= 80;
    if (dailyBonusApplied) earnedStickers += policy.dailyAchievement80Bonus;
    if (requiredRate == 100 && requiredItems.isNotEmpty) earnedStickers += policy.allRequiredCompletionBonus;

    final weeklyRate =
        ((dataset.recentPerformance.weeklyAchievementRate * 6 + overallRate) / 7).roundToDouble();

    final allowance = dataset.allowancePolicy;
    int? expectedAllowance;
    var allowanceCandidate = false;
    if (allowance.enabled) {
      for (final condition in allowance.conditions) {
        if (weeklyRate >= condition.achievementRate) {
          allowanceCandidate = true;
          expectedAllowance = condition.amount;
        }
      }
    }

    return DailyReviewResponse(
      result: 'success',
      studentId: dataset.student.studentId,
      reviewDate: dateStr,
      achievement: AchievementStats(
        totalPlanCount: total,
        completedPlanCount: completedItems.length,
        overallAchievementRate: overallRate,
        requiredAchievementRate: requiredRate,
        onTimeCompletionRate: onTimeRate,
        totalPlannedMinutes: totalPlanned,
        totalActualMinutes: totalActual,
      ),
      subjectResults: subjectResults,
      completedWell: completedWell.isEmpty ? ['오늘도 계획을 확인하며 하루를 시작했어요.'] : completedWell,
      improvementPoints: improvementPoints,
      studentMessage: studentMessage,
      parentMessage: parentMessage,
      rewardResult: RewardResult(
        earnedStickerCount: earnedStickers,
        dailyBonusApplied: dailyBonusApplied,
        weeklyAchievementRate: weeklyRate,
        allowanceCandidate: allowanceCandidate,
        expectedAllowance: expectedAllowance,
        parentApprovalRequired: true,
      ),
    );
  }
}
