/// Reward forecast returned alongside a daily plan. Per the AI Teacher spec,
/// this is always an *estimate* -- allowance is never confirmed by the AI,
/// so [parentApprovalRequired] must always be true.
class RewardForecast {
  final int estimatedPlanStickerReward;
  final int dailyBonusStickerPossible;
  final int maximumEstimatedStickerReward;
  final bool allowancePolicyExists;
  final String? allowancePeriod;
  final double currentWeeklyAchievementRate;
  final double? targetAchievementRate;
  final int? expectedAllowance;
  final String currency;
  final bool parentApprovalRequired;
  final String message;

  const RewardForecast({
    required this.estimatedPlanStickerReward,
    required this.dailyBonusStickerPossible,
    required this.maximumEstimatedStickerReward,
    required this.allowancePolicyExists,
    this.allowancePeriod,
    required this.currentWeeklyAchievementRate,
    this.targetAchievementRate,
    this.expectedAllowance,
    this.currency = 'KRW',
    this.parentApprovalRequired = true,
    required this.message,
  });

  factory RewardForecast.fromJson(Map<String, dynamic> json) => RewardForecast(
        estimatedPlanStickerReward: json['estimatedPlanStickerReward'] as int,
        dailyBonusStickerPossible: json['dailyBonusStickerPossible'] as int,
        maximumEstimatedStickerReward: json['maximumEstimatedStickerReward'] as int,
        allowancePolicyExists: json['allowancePolicyExists'] as bool,
        allowancePeriod: json['allowancePeriod'] as String?,
        currentWeeklyAchievementRate: (json['currentWeeklyAchievementRate'] as num).toDouble(),
        targetAchievementRate: (json['targetAchievementRate'] as num?)?.toDouble(),
        expectedAllowance: json['expectedAllowance'] as int?,
        currency: json['currency'] as String? ?? 'KRW',
        parentApprovalRequired: json['parentApprovalRequired'] as bool? ?? true,
        message: json['message'] as String,
      );

  Map<String, dynamic> toJson() => {
        'estimatedPlanStickerReward': estimatedPlanStickerReward,
        'dailyBonusStickerPossible': dailyBonusStickerPossible,
        'maximumEstimatedStickerReward': maximumEstimatedStickerReward,
        'allowancePolicyExists': allowancePolicyExists,
        'allowancePeriod': allowancePeriod,
        'currentWeeklyAchievementRate': currentWeeklyAchievementRate,
        'targetAchievementRate': targetAchievementRate,
        'expectedAllowance': expectedAllowance,
        'currency': currency,
        'parentApprovalRequired': true,
        'message': message,
      };
}
