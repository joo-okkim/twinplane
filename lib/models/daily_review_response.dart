class AchievementStats {
  final int totalPlanCount;
  final int completedPlanCount;
  final int overallAchievementRate;
  final int requiredAchievementRate;
  final int onTimeCompletionRate;
  final int totalPlannedMinutes;
  final int totalActualMinutes;

  const AchievementStats({
    required this.totalPlanCount,
    required this.completedPlanCount,
    required this.overallAchievementRate,
    required this.requiredAchievementRate,
    required this.onTimeCompletionRate,
    required this.totalPlannedMinutes,
    required this.totalActualMinutes,
  });

  Map<String, dynamic> toJson() => {
        'totalPlanCount': totalPlanCount,
        'completedPlanCount': completedPlanCount,
        'overallAchievementRate': overallAchievementRate,
        'requiredAchievementRate': requiredAchievementRate,
        'onTimeCompletionRate': onTimeCompletionRate,
        'totalPlannedMinutes': totalPlannedMinutes,
        'totalActualMinutes': totalActualMinutes,
      };
}

class SubjectResult {
  final String subject;
  final int plannedMinutes;
  final int actualMinutes;
  final int achievementRate;
  final String analysis;

  const SubjectResult({
    required this.subject,
    required this.plannedMinutes,
    required this.actualMinutes,
    required this.achievementRate,
    required this.analysis,
  });

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'plannedMinutes': plannedMinutes,
        'actualMinutes': actualMinutes,
        'achievementRate': achievementRate,
        'analysis': analysis,
      };
}

/// Per spec: earnedStickerCount/allowanceCandidate are estimates the AI
/// computes from policy; parentApprovalRequired must always be true --
/// AI Teacher never confirms allowance payout itself.
class RewardResult {
  final int earnedStickerCount;
  final bool dailyBonusApplied;
  final double weeklyAchievementRate;
  final bool allowanceCandidate;
  final int? expectedAllowance;
  final String currency;
  final bool parentApprovalRequired;

  const RewardResult({
    required this.earnedStickerCount,
    required this.dailyBonusApplied,
    required this.weeklyAchievementRate,
    required this.allowanceCandidate,
    this.expectedAllowance,
    this.currency = 'KRW',
    this.parentApprovalRequired = true,
  });

  Map<String, dynamic> toJson() => {
        'earnedStickerCount': earnedStickerCount,
        'dailyBonusApplied': dailyBonusApplied,
        'weeklyAchievementRate': weeklyAchievementRate,
        'allowanceCandidate': allowanceCandidate,
        'expectedAllowance': expectedAllowance,
        'currency': currency,
        'parentApprovalRequired': true,
      };
}

class DailyReviewResponse {
  final String result;
  final int studentId;
  final String reviewDate;
  final AchievementStats achievement;
  final List<SubjectResult> subjectResults;
  final List<String> completedWell;
  final List<String> improvementPoints;
  final String studentMessage;
  final String parentMessage;
  final RewardResult rewardResult;

  const DailyReviewResponse({
    required this.result,
    required this.studentId,
    required this.reviewDate,
    required this.achievement,
    required this.subjectResults,
    required this.completedWell,
    required this.improvementPoints,
    required this.studentMessage,
    required this.parentMessage,
    required this.rewardResult,
  });

  Map<String, dynamic> toJson() => {
        'result': result,
        'studentId': studentId,
        'reviewDate': reviewDate,
        'achievement': achievement.toJson(),
        'subjectResults': subjectResults.map((s) => s.toJson()).toList(),
        'completedWell': completedWell,
        'improvementPoints': improvementPoints,
        'studentMessage': studentMessage,
        'parentMessage': parentMessage,
        'rewardResult': rewardResult.toJson(),
      };
}
