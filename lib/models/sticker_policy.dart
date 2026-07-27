class StickerPolicy {
  final int requiredPlanCompletion;
  final int recommendedPlanCompletion;
  final int onTimeBonus;
  final int dailyAchievement80Bonus;
  final int allRequiredCompletionBonus;

  const StickerPolicy({
    required this.requiredPlanCompletion,
    required this.recommendedPlanCompletion,
    required this.onTimeBonus,
    required this.dailyAchievement80Bonus,
    required this.allRequiredCompletionBonus,
  });

  factory StickerPolicy.fromJson(Map<String, dynamic> json) => StickerPolicy(
        requiredPlanCompletion: json['requiredPlanCompletion'] as int,
        recommendedPlanCompletion: json['recommendedPlanCompletion'] as int,
        onTimeBonus: json['onTimeBonus'] as int,
        dailyAchievement80Bonus: json['dailyAchievement80Bonus'] as int,
        allRequiredCompletionBonus: json['allRequiredCompletionBonus'] as int,
      );

  Map<String, dynamic> toJson() => {
        'requiredPlanCompletion': requiredPlanCompletion,
        'recommendedPlanCompletion': recommendedPlanCompletion,
        'onTimeBonus': onTimeBonus,
        'dailyAchievement80Bonus': dailyAchievement80Bonus,
        'allRequiredCompletionBonus': allRequiredCompletionBonus,
      };
}
