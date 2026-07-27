class RecentPerformance {
  final double dailyAchievementRate7Days;
  final double weeklyAchievementRate;
  final int consecutiveCompletionDays;
  final String mostCompletedSubject;
  final String leastCompletedSubject;
  final int averageStartDelayMinutes;

  const RecentPerformance({
    required this.dailyAchievementRate7Days,
    required this.weeklyAchievementRate,
    required this.consecutiveCompletionDays,
    required this.mostCompletedSubject,
    required this.leastCompletedSubject,
    required this.averageStartDelayMinutes,
  });

  factory RecentPerformance.fromJson(Map<String, dynamic> json) => RecentPerformance(
        dailyAchievementRate7Days: (json['dailyAchievementRate7Days'] as num).toDouble(),
        weeklyAchievementRate: (json['weeklyAchievementRate'] as num).toDouble(),
        consecutiveCompletionDays: json['consecutiveCompletionDays'] as int,
        mostCompletedSubject: json['mostCompletedSubject'] as String,
        leastCompletedSubject: json['leastCompletedSubject'] as String,
        averageStartDelayMinutes: json['averageStartDelayMinutes'] as int,
      );

  Map<String, dynamic> toJson() => {
        'dailyAchievementRate7Days': dailyAchievementRate7Days,
        'weeklyAchievementRate': weeklyAchievementRate,
        'consecutiveCompletionDays': consecutiveCompletionDays,
        'mostCompletedSubject': mostCompletedSubject,
        'leastCompletedSubject': leastCompletedSubject,
        'averageStartDelayMinutes': averageStartDelayMinutes,
      };
}
