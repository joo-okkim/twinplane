class AllowanceCondition {
  final double achievementRate;
  final int amount;

  const AllowanceCondition({required this.achievementRate, required this.amount});

  factory AllowanceCondition.fromJson(Map<String, dynamic> json) => AllowanceCondition(
        achievementRate: (json['achievementRate'] as num).toDouble(),
        amount: json['amount'] as int,
      );

  Map<String, dynamic> toJson() => {
        'achievementRate': achievementRate,
        'amount': amount,
      };
}

class AllowancePolicy {
  final bool enabled;
  final String period;
  final List<AllowanceCondition> conditions;
  final bool parentApprovalRequired;

  const AllowancePolicy({
    required this.enabled,
    required this.period,
    required this.conditions,
    required this.parentApprovalRequired,
  });

  factory AllowancePolicy.fromJson(Map<String, dynamic> json) => AllowancePolicy(
        enabled: json['enabled'] as bool,
        period: json['period'] as String,
        conditions: (json['conditions'] as List)
            .map((e) => AllowanceCondition.fromJson(e as Map<String, dynamic>))
            .toList(),
        parentApprovalRequired: json['parentApprovalRequired'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'period': period,
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'parentApprovalRequired': parentApprovalRequired,
      };
}
