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

  factory AchievementStats.fromJson(Map<String, dynamic> json) => AchievementStats(
        totalPlanCount: json['totalPlanCount'] as int,
        completedPlanCount: json['completedPlanCount'] as int,
        overallAchievementRate: json['overallAchievementRate'] as int,
        requiredAchievementRate: json['requiredAchievementRate'] as int,
        onTimeCompletionRate: json['onTimeCompletionRate'] as int,
        totalPlannedMinutes: json['totalPlannedMinutes'] as int,
        totalActualMinutes: json['totalActualMinutes'] as int,
      );

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

  factory SubjectResult.fromJson(Map<String, dynamic> json) => SubjectResult(
        subject: json['subject'] as String,
        plannedMinutes: json['plannedMinutes'] as int,
        actualMinutes: json['actualMinutes'] as int,
        achievementRate: json['achievementRate'] as int,
        analysis: json['analysis'] as String,
      );

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

  factory RewardResult.fromJson(Map<String, dynamic> json) => RewardResult(
        earnedStickerCount: json['earnedStickerCount'] as int,
        dailyBonusApplied: json['dailyBonusApplied'] as bool,
        weeklyAchievementRate: (json['weeklyAchievementRate'] as num).toDouble(),
        allowanceCandidate: json['allowanceCandidate'] as bool,
        expectedAllowance: json['expectedAllowance'] as int?,
        currency: json['currency'] as String? ?? 'KRW',
        parentApprovalRequired: json['parentApprovalRequired'] as bool? ?? true,
      );

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

  factory DailyReviewResponse.fromJson(Map<String, dynamic> json) => DailyReviewResponse(
        result: json['result'] as String,
        studentId: json['studentId'] as int,
        reviewDate: json['reviewDate'] as String,
        achievement: AchievementStats.fromJson(json['achievement'] as Map<String, dynamic>),
        subjectResults: (json['subjectResults'] as List)
            .map((e) => SubjectResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        completedWell: (json['completedWell'] as List).map((e) => e as String).toList(),
        improvementPoints: (json['improvementPoints'] as List).map((e) => e as String).toList(),
        studentMessage: json['studentMessage'] as String,
        parentMessage: json['parentMessage'] as String,
        rewardResult: RewardResult.fromJson(json['rewardResult'] as Map<String, dynamic>),
      );

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
