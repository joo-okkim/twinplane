class DifficultyBalance {
  final int easy;
  final int normal;
  final int hard;

  const DifficultyBalance({required this.easy, required this.normal, required this.hard});

  int get total => easy + normal + hard;

  factory DifficultyBalance.fromJson(Map<String, dynamic> json) => DifficultyBalance(
        easy: json['easy'] as int,
        normal: json['normal'] as int,
        hard: json['hard'] as int,
      );

  Map<String, dynamic> toJson() => {'easy': easy, 'normal': normal, 'hard': hard};
}

class PlanSummary {
  final String title;
  final int totalStudyMinutes;
  final int requiredStudyMinutes;
  final int recommendedStudyMinutes;
  final int breakMinutes;
  final int planItemCount;
  final int requiredPlanCount;
  final DifficultyBalance difficultyBalance;
  final int expectedAchievementRate;
  final int planConfidenceScore;

  const PlanSummary({
    required this.title,
    required this.totalStudyMinutes,
    required this.requiredStudyMinutes,
    required this.recommendedStudyMinutes,
    required this.breakMinutes,
    required this.planItemCount,
    required this.requiredPlanCount,
    required this.difficultyBalance,
    required this.expectedAchievementRate,
    required this.planConfidenceScore,
  });

  factory PlanSummary.fromJson(Map<String, dynamic> json) => PlanSummary(
        title: json['title'] as String,
        totalStudyMinutes: json['totalStudyMinutes'] as int,
        requiredStudyMinutes: json['requiredStudyMinutes'] as int,
        recommendedStudyMinutes: json['recommendedStudyMinutes'] as int,
        breakMinutes: json['breakMinutes'] as int,
        planItemCount: json['planItemCount'] as int,
        requiredPlanCount: json['requiredPlanCount'] as int,
        difficultyBalance:
            DifficultyBalance.fromJson(json['difficultyBalance'] as Map<String, dynamic>),
        expectedAchievementRate: json['expectedAchievementRate'] as int,
        planConfidenceScore: json['planConfidenceScore'] as int,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'totalStudyMinutes': totalStudyMinutes,
        'requiredStudyMinutes': requiredStudyMinutes,
        'recommendedStudyMinutes': recommendedStudyMinutes,
        'breakMinutes': breakMinutes,
        'planItemCount': planItemCount,
        'requiredPlanCount': requiredPlanCount,
        'difficultyBalance': difficultyBalance.toJson(),
        'expectedAchievementRate': expectedAchievementRate,
        'planConfidenceScore': planConfidenceScore,
      };
}
