class IncompletePlan {
  final int planItemId;
  final String subject;
  final String title;
  final String originalDate;
  final int estimatedMinutes;
  final double completionRate;
  final String reason;
  final String priority;

  const IncompletePlan({
    required this.planItemId,
    required this.subject,
    required this.title,
    required this.originalDate,
    required this.estimatedMinutes,
    required this.completionRate,
    required this.reason,
    required this.priority,
  });

  factory IncompletePlan.fromJson(Map<String, dynamic> json) => IncompletePlan(
        planItemId: json['planItemId'] as int,
        subject: json['subject'] as String,
        title: json['title'] as String,
        originalDate: json['originalDate'] as String,
        estimatedMinutes: json['estimatedMinutes'] as int,
        completionRate: (json['completionRate'] as num).toDouble(),
        reason: json['reason'] as String,
        priority: json['priority'] as String,
      );

  Map<String, dynamic> toJson() => {
        'planItemId': planItemId,
        'subject': subject,
        'title': title,
        'originalDate': originalDate,
        'estimatedMinutes': estimatedMinutes,
        'completionRate': completionRate,
        'reason': reason,
        'priority': priority,
      };
}
